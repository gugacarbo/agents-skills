#!/usr/bin/env python3
"""Run private orchestration measurements and retain raw Codex evidence."""
import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time


HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parents[2]
DEFAULT_OUTPUT = (REPOSITORY.parent / 'orchestrate-implementation-workspace' /
                  f'measurement-{dt.date.today().isoformat()}')
REVIEW_MEASURE = REPOSITORY / 'skills/orchestrate-review/evals/measure.py'


def telemetry():
    spec = importlib.util.spec_from_file_location('review_measure', REVIEW_MEASURE)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def fixture_hash(fixture):
    digest = hashlib.sha256()
    for source in [fixture / 'plan.md', *sorted((fixture / 'base').rglob('*'))]:
        if source.is_file():
            digest.update(str(source.relative_to(fixture)).encode())
            digest.update(source.read_bytes())
    return digest.hexdigest()


def summarize_usage(agents):
    keys = ('input_tokens', 'cached_input_tokens', 'cache_write_input_tokens',
            'output_tokens', 'reasoning_output_tokens', 'total_tokens')
    if not agents or any(not {'input_tokens', 'output_tokens', 'total_tokens'} <= set(agent.get('usage') or {})
                         or agent.get('status') != 'task_complete' for agent in agents):
        return None
    return {key: sum(agent['usage'].get(key, 0) for agent in agents) for key in keys}


def eligible(timing, agents):
    return bool(timing.get('completion_status', 'completed') == 'completed'
                and timing.get('exit_code') == 0 and not timing.get('timed_out')
                and not timing.get('excluded_from_comparison')
                and summarize_usage(agents) is not None
                and all(a.get('model') == 'gpt-6-luna' and a.get('effort') == 'medium' for a in agents)
                and (timing.get('kind') != 'execution' or len(agents) >= 2))


def skill_snapshot(root, variant, baseline_skill=None, original_ref=None):
    snapshot = root / 'snapshots' / variant
    if (snapshot / 'SKILL.md').exists():
        return snapshot
    if variant == 'original':
        if baseline_skill:
            source = Path(baseline_skill).resolve()
        elif original_ref:
            snapshot.mkdir(parents=True, exist_ok=True)
            files = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', original_ref,
                'skills/orchestrate-implementation'], cwd=REPOSITORY, text=True).splitlines()
            for filename in files:
                relative = Path(filename).relative_to('skills/orchestrate-implementation')
                if relative.suffix != '.md' or {'evals', 'tests'} & set(relative.parts):
                    continue
                target = snapshot / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(subprocess.check_output(['git', 'show', f'{original_ref}:{filename}'], cwd=REPOSITORY, text=True))
            if (snapshot / 'SKILL.md').exists():
                return snapshot
            raise SystemExit(f'Git ref {original_ref} has no implementation SKILL.md')
        else:
            raise SystemExit('Original snapshot missing; pass --baseline-skill or --original-ref')
    else:
        source = REPOSITORY / 'skills/orchestrate-implementation'
    shutil.copytree(source, snapshot, ignore=shutil.ignore_patterns('evals', 'tests', '__pycache__'))
    return snapshot


def load_cases(kind):
    data = json.loads((HERE / 'evals.json').read_text())
    catalog_kind = {'decisions': 'decision', 'execution': 'execution'}[kind]
    cases = [case for case in data['evals'] if case.get('measurement_kind') == catalog_kind]
    return {str(case['id']): case for case in cases}


def run_prompt(case, kind, variant, skill_path, workspace, repo_snapshot):
    skill_intro = (f"Use the orchestrate-implementation skill at {skill_path / 'SKILL.md'}.\n"
                   if variant != 'control' else '')
    read_instructions = ('Do not read or invoke any skill for this control sample.' if variant == 'control'
                         else 'Read only the selected skill snapshot and directly needed reference files.')
    if kind == 'decisions':
        return f'''{skill_intro}{read_instructions} Do not inspect other variants or evaluation artifacts. This is a read-only decision measurement: answer what the controller should decide and why; do not dispatch subagents, edit files, or execute the plan.

Controlled model constraint: all roles, if discussed, use gpt-6-luna at medium reasoning effort. This is not approval to dispatch in this decision-only measurement.

Scenario:
{case['prompt']}
'''
    fixture_name = case.get('fixture') or {
        'bounded-sequential-implementation': 'usage-enhancement',
        'sequential-deliveries-without-final': 'three-delivery-units',
    }.get(case['name'])
    plan = (HERE / 'fixtures/measurement' / fixture_name / 'plan.md').read_text()
    return f'''{skill_intro}{case['prompt']}

Execute this plan in {workspace}. The user's plan is {repo_snapshot / 'plan.md'}.

Read only the selected skill snapshot and its needed role/reference files. Do not inspect other skill versions, sibling measurement runs, or hidden fixture assertions. Implement the requested changes, run the public validation specified by the plan, and report actual commits and validation evidence. The fixture is disposable. Do not modify files outside {workspace} except the selected run output directory.

Model constraint: ALL agents must use explicitly approved gpt-6-luna at medium reasoning effort. Use exposed supported controls and never select a different model. If the harness cannot dispatch this model, report the limitation and stop; do not simulate a child or silently substitute another model. Use native subagents and wait for them to complete. User has explicitly selected the existing fixture checkout as integration workspace and approved sequential execution when required by dependency or policy. Respect the plan's review instruction.

Plan:
{plan}
'''


def prepare_execution(run, fixture, case):
    workspace = run / 'repo'
    workspace.mkdir(parents=True)
    shutil.copytree(fixture / 'base', workspace, dirs_exist_ok=True)
    shutil.copy2(fixture / 'plan.md', workspace / 'plan.md')
    subprocess.run(['git', 'init', '-q'], cwd=workspace, check=True)
    subprocess.run(['git', 'add', '.'], cwd=workspace, check=True)
    env = dict(os.environ, GIT_AUTHOR_NAME='Implementation Eval',
               GIT_AUTHOR_EMAIL='eval@example.invalid', GIT_COMMITTER_NAME='Implementation Eval',
               GIT_COMMITTER_EMAIL='eval@example.invalid')
    subprocess.run(['git', 'commit', '-qm', 'Fixture base'], cwd=workspace, env=env, check=True)
    (run / 'fixture.json').write_text(json.dumps({'case': case['name'], 'base': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=workspace, text=True).strip(),
        'workspace': str(workspace), 'fixture': str(fixture), 'fixture_sha256': fixture_hash(fixture)}, indent=2))
    return workspace


@contextlib.contextmanager
def execution_slot(lock):
    """Exclude other measurement runners; yield seconds spent waiting for the slot."""
    lock = Path(lock)
    lock.parent.mkdir(parents=True, exist_ok=True)
    with lock.open('a') as handle:
        started = time.monotonic()
        fcntl.flock(handle, fcntl.LOCK_EX)
        waiting = time.monotonic() - started
        try:
            yield waiting
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


def execute(case_id, case, kind, variant, repetition, root, timeout):
    variant_layout = {'original': 'old_skill', 'current': 'new_skill', 'control': 'without_skill'}[variant]
    case_layout = root / f'eval-{case_id}' / variant_layout
    case_layout.mkdir(parents=True, exist_ok=True)
    run_number = repetition
    while (case_layout / f'run-{run_number}').exists():
        run_number += 1
    run = case_layout / f'run-{run_number}'
    run.mkdir(parents=True, exist_ok=False)
    fixture_name = case.get('fixture') or {
        'bounded-sequential-implementation': 'usage-enhancement',
        'sequential-deliveries-without-final': 'three-delivery-units',
    }.get(case['name'])
    fixture = HERE / 'fixtures/measurement' / fixture_name if fixture_name else None
    if kind == 'execution':
        if fixture is None:
            raise ValueError(f'No fixture configured for execution case {case_id}')
        workspace = prepare_execution(run, fixture, case)
        repo_snapshot = workspace
    else:
        workspace = run
        repo_snapshot = run
        (run / 'scenario.json').write_text(json.dumps({'id': case_id, 'name': case['name'],
                                                       'prompt': case['prompt']}, indent=2))
    skill_path = root / 'snapshots' / variant
    if variant == 'control':
        skill_path = root / 'snapshots' / 'original'
    prompt = run_prompt(case, kind, variant, skill_path, workspace, repo_snapshot)
    (run / 'eval_metadata.json').write_text(json.dumps({'eval_id': int(case_id),
        'prompt': case['prompt'], 'kind': kind, 'variant': variant}, indent=2))
    (run / 'outputs').mkdir()
    (run / 'prompt.txt').write_text(prompt)
    command = ['codex', 'exec', '--ignore-user-config', '--json', '-m', 'gpt-6-luna',
               '-c', 'model_reasoning_effort="medium"', '-c', 'features.multi_agent=true',
               '-c', 'features.skip_host_skill_discovery=true', '-c', 'agents.max_threads=4',
               '-c', 'approval_policy="never"', '-s', 'danger-full-access', '-C', str(workspace),
               '-o', str(run / 'outputs/final.md'), '-']
    if kind == 'decisions':
        command.insert(3, '--skip-git-repo-check')
    (run / 'command.json').write_text(json.dumps(command, indent=2))
    started = dt.datetime.now(dt.timezone.utc).isoformat()
    before = time.monotonic()
    timed_out = False
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
    with (run / 'events.jsonl').open('w') as events, (run / 'stderr.log').open('w') as error:
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=events, stderr=error,
                                   cwd=workspace, env=env, start_new_session=True)
        try:
            process.communicate(prompt.encode(), timeout=timeout)
        except subprocess.TimeoutExpired:
            timed_out = True
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
    if timed_out:
        completion_status = 'timed_out'
    elif process.returncode != 0:
        completion_status = 'cli_failure'
    else:
        completion_status = 'completed'
    timing = {'started_at': started, 'completed_at': dt.datetime.now(dt.timezone.utc).isoformat(),
              'duration_seconds': time.monotonic() - before, 'exit_code': process.returncode,
              'timed_out': timed_out, 'completion_status': completion_status,
              'variant': variant, 'kind': kind, 'case_id': case_id,
              'repetition': repetition, 'model_requested': 'gpt-6-luna',
              'effort_requested': 'medium'}
    if kind == 'execution' and completion_status == 'completed':
        private_tests = fixture / 'private_tests.py'
        grader = subprocess.run([sys.executable, str(private_tests), str(workspace)], cwd=workspace,
                                text=True, capture_output=True, timeout=60)
        (run / 'grading.stdout.log').write_text(grader.stdout)
        (run / 'grading.stderr.log').write_text(grader.stderr)
        (run / 'grading.json').write_text(json.dumps({'exit_code': grader.returncode,
            'passed': grader.returncode == 0, 'grader': str(private_tests),
            'summary': {'passed': int(grader.returncode == 0), 'failed': int(grader.returncode != 0),
                        'total': 1, 'pass_rate': float(grader.returncode == 0)},
            'expectations': [{'text': 'Private behavior assertions pass.',
                              'passed': grader.returncode == 0,
                              'evidence': grader.stdout + grader.stderr}]}, indent=2))
    (run / 'timing.json').write_text(json.dumps(timing, indent=2))
    print(json.dumps({'run': str(run), **timing}), flush=True)
    return run


def aggregate(root):
    helper = telemetry()
    index = helper.session_index()
    summaries = []
    for timing_path in sorted(root.glob('eval-*/*/run-*/timing.json')):
        if timing_path.parent.name.startswith('run-') is False:
            continue
        run = timing_path.parent
        timing = json.loads(timing_path.read_text())
        metadata_path = run / 'eval_metadata.json'
        metadata = json.loads(metadata_path.read_text()) if metadata_path.exists() else {}
        timing = {**metadata, **timing}
        events = helper.read_events(run / 'events.jsonl')
        thread = next((event.get('thread_id') for event in events
                       if event.get('type') == 'thread.started'), None)
        ids = {thread} if thread else set()
        while True:
            children = {sid for sid, (_, meta) in index.items() if helper.parent_id(meta) in ids}
            if children <= ids:
                break
            ids |= children
        agents = [helper.extract_agent(*index[sid]) for sid in sorted(ids) if sid in index]
        (run / 'agents.json').write_text(json.dumps(agents, indent=2))
        totals = summarize_usage(agents)
        complete = totals is not None
        summary = {**timing, 'root_thread_id': thread, 'agent_count_including_controller': len(agents) if agents else None,
                   'dispatches_observed': len(agents) - 1 if agents else timing.get('dispatches_observed'),
                   'usage_complete': complete, 'eligible_for_comparison': eligible(timing, agents),
                   'usage': totals, 'tool_calls': sum(a['tool_calls'] for a in agents),
                   'models_observed': sorted({a['model'] for a in agents if a['model']}),
                   'efforts_observed': sorted({a['effort'] for a in agents if a['effort']}),
                   'resumes_observed': sum(max(0, a['turns_completed'] - 1) for a in agents),
                   'agents': [{'id': a['id'], 'parent_id': a['parent_id'], 'model': a['model'],
                               'effort': a['effort'], 'status': a['status'], 'usage': a['usage'],
                               'tools': a['tools'], 'commands': a['commands']} for a in agents],
                   'run_dir': str(run)}
        grading_path = run / 'grading.json'
        if grading_path.exists():
            summary['grading'] = json.loads(grading_path.read_text())
        timing['total_duration_seconds'] = timing.get('duration_seconds')
        timing['total_tokens'] = totals['total_tokens'] if totals else None
        timing_path.write_text(json.dumps(timing, indent=2))
        if totals:
            summary['uncached_input_tokens'] = totals['input_tokens'] - totals['cached_input_tokens']
        (run / 'summary.json').write_text(json.dumps(summary, indent=2))
        summaries.append(summary)
    (root / 'benchmark.json').write_text(json.dumps({'runs': summaries}, indent=2))
    return summaries



def aggregate_desktop(root, controllers):
    """Aggregate native desktop sessions by controller path, including descendants."""
    helper = telemetry()
    index = helper.session_index()
    results = []
    for mapping in controllers:
        variant, separator, prefix = mapping.partition('=')
        if not separator or not prefix.startswith('/'):
            raise SystemExit('--desktop-controller requires variant=/canonical/agent/path')
        selected = [(path, meta) for path, meta in index.values()
                    if meta.get('agent_path') == prefix
                    or str(meta.get('agent_path', '')).startswith(prefix + '/')]
        agents = [helper.extract_agent(path, meta) for path, meta in selected]
        controller = next((a for a in agents if a['agent_path'] == prefix), None)
        totals = summarize_usage(agents)
        results.append({'variant': variant, 'controller_path': prefix,
                        'model': sorted({a['model'] for a in agents if a['model']}),
                        'effort': sorted({a['effort'] for a in agents if a['effort']}),
                        'agents_including_controller': len(agents) if agents else None,
                        'dispatches': len(agents) - 1 if agents else None,
                        'wall_seconds': controller['duration_seconds'] if controller else None,
                        'usage': totals,
                        'uncached_input_tokens': totals['input_tokens'] - totals['cached_input_tokens'] if totals else None,
                        'eligible_for_comparison': bool(totals and all(a['model'] == 'gpt-6-luna' and a['effort'] == 'medium' for a in agents)),
                        'sessions': [{'id': meta['id'], 'path': str(path)} for path, meta in selected],
                        'agents': agents})
    destination = root / 'desktop-benchmark.json'
    destination.write_text(json.dumps({'runs': results, 'limitations': [
        'Two execution cases share each variant controller; compare the combined batch, not independent per-case controller tokens.',
        'Single pilot per variant; wall time includes shared team-capacity waiting.'
    ]}, indent=2))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--variant', choices=('original', 'current', 'control'))
    parser.add_argument('--kind', choices=('decisions', 'execution'))
    parser.add_argument('--case', action='append', help='Catalog case ID; may be repeated')
    parser.add_argument('--output', type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument('--baseline-skill', type=Path, help='Existing original skill snapshot directory')
    parser.add_argument('--original-ref', help='Git ref from which to create the original snapshot')
    parser.add_argument('--repeat', type=int, default=1)
    parser.add_argument('--timeout', type=int, default=600)
    parser.add_argument('--aggregate-only', action='store_true')
    parser.add_argument('--desktop-controller', action='append', default=[],
                        help='Aggregate native desktop evidence: variant=/canonical/agent/path')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    if not args.aggregate_only:
        if not args.variant or not args.kind:
            parser.error('--variant and --kind are required unless --aggregate-only is used')
        if args.repeat < 1:
            parser.error('--repeat must be >= 1')
        cases = load_cases(args.kind)
        if args.case:
            missing = sorted(set(args.case) - set(cases))
            if missing:
                parser.error(f'unknown {args.kind} case ID(s): {", ".join(missing)}')
            cases = {case_id: case for case_id, case in cases.items() if case_id in args.case}
        if not cases:
            raise SystemExit(f'No measurement cases found for kind={args.kind}; add measurement_kind and measurement_only to evals.json.')
        with execution_slot(args.output / 'execution.lock') as waiting:
            if waiting > 0:
                print(json.dumps({'slot_wait_seconds': waiting}), flush=True)
            if args.variant != 'control':
                skill_snapshot(args.output, args.variant, args.baseline_skill, args.original_ref)
            for case_id, case in cases.items():
                for repetition in range(1, args.repeat + 1):
                    run = execute(case_id, case, args.kind, args.variant, repetition, args.output, args.timeout)
                    aggregate(args.output)
                    result = json.loads((run / 'summary.json').read_text())
                    if not result['eligible_for_comparison']:
                        raise SystemExit(f'Run incomplete or model/telemetry mismatch: {run}; preserve evidence before retrying.')
    else:
        aggregate(args.output)
    if args.desktop_controller:
        aggregate_desktop(args.output, args.desktop_controller)


if __name__ == '__main__':
    main()
