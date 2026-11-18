#!/usr/bin/env python3
"""Measure full Codex review orchestrations, including descendant sessions.

Run only on disposable fixture repositories. Uses existing authenticated CLI and
preserves JSONL evidence; missing telemetry remains null, never zero.
"""
import argparse
import concurrent.futures
import csv
import ast
import re
import statistics
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time


def git(workspace, *args):
    return subprocess.check_output(['git', *args], cwd=workspace, text=True).strip()


def snapshots(root, original_ref, baseline_skill=None, candidate_skill=None):
    """Freeze runtime Markdown only; fixture truth never enters agent snapshots."""
    repository = Path(__file__).resolve().parents[3]
    for variant in ('original', 'current'):
        destination = root / 'snapshots' / variant
        if (destination / 'SKILL.md').exists():
            continue
        destination.mkdir(parents=True, exist_ok=True)
        if variant == 'original' and baseline_skill is None:
            paths = git(repository, 'ls-tree', '-r', '--name-only', original_ref,
                        'skills/orchestrate-review').splitlines()
            documents = [(Path(path).relative_to('skills/orchestrate-review'),
                          git(repository, 'show', f'{original_ref}:{path}') + '\n')
                         for path in paths if path.endswith('.md') and
                         not {'evals', 'tests'} & set(Path(path).parts)]
        else:
            source = Path(baseline_skill if variant == 'original' else candidate_skill or repository / 'skills/orchestrate-review').resolve()
            documents = [(path.relative_to(source), path.read_text())
                         for path in source.rglob('*.md') if
                         not {'evals', 'tests'} & set(path.relative_to(source).parts)]
        for relative, text in documents:
            target = destination / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text)
    metadata = root / 'metadata.json'
    if not metadata.exists():
        metadata.write_text(json.dumps({'original_git_revision': git(repository, 'rev-parse', original_ref) if baseline_skill is None else None,
                                       'baseline_skill': str(baseline_skill) if baseline_skill else None,
                                       'model': 'gpt-6-luna', 'reasoning_effort': 'medium',
                                       'permission_profile': 'host unrestricted; agent tasks read-only'}, indent=2))


def prepare(root, fixture_root, case, variant, repetition):
    run = root / 'runs' / case / f'repeat-{repetition}' / variant
    if (run / 'timing.json').exists():
        raise RuntimeError(f'Refusing to overwrite measured run: {run}')
    workspace = run / 'repo'
    workspace.mkdir(parents=True, exist_ok=True)
    for source in (fixture_root / case / 'base').iterdir():
        if source.is_dir():
            shutil.copytree(source, workspace / source.name, dirs_exist_ok=True)
        else:
            shutil.copy2(source, workspace / source.name)
    git(workspace, 'init', '-q')
    git(workspace, 'add', '.')
    git(workspace, '-c', 'user.name=Review Eval', '-c', 'user.email=eval@example.invalid',
        'commit', '-qm', 'Fixture base')
    base = git(workspace, 'rev-parse', 'HEAD')
    # The head is a full fixture tree, not an overlay retaining deleted base files.
    for target in workspace.iterdir():
        if target.name == '.git':
            continue
        if target.is_dir():
            shutil.rmtree(target)
        else:
            target.unlink()
    for source in (fixture_root / case / 'head').iterdir():
        if source.is_dir():
            shutil.copytree(source, workspace / source.name, dirs_exist_ok=True)
        else:
            shutil.copy2(source, workspace / source.name)
    git(workspace, 'add', '.')
    git(workspace, '-c', 'user.name=Review Eval', '-c', 'user.email=eval@example.invalid',
        'commit', '-qm', 'Change under review')
    head = git(workspace, 'rev-parse', 'HEAD')
    diff = git(workspace, 'diff', base, head)
    (run / 'diff.patch').write_text(diff + '\n')
    requirements = (fixture_root / case / 'requirements.md').read_text()
    prompt = f'''Use the orchestrate-review skill at {root / 'snapshots' / variant / 'SKILL.md'}.
Perform a real complete review of {base}..{head} in {workspace}.
Dispatch actual independent subagents according to that skill; this is not a routing simulation.
Read only the selected skill and its needed role/reference files, not other versions or evaluation artifacts.

User model constraint for this controlled measurement: ALL agents, including the
controller, primary reviewers and final reviewers, must use gpt-6-luna at medium
reasoning effort. Respect this over default skill model preferences. Do not change
models or effort. Dispatch fresh-context subagents (fork_turns none) with self-contained
tasks. Model profiles can still be reported as requested conceptual routing.

Requirements supplied by the user:
{requirements}

Review read-only; do not fix implementation or commit. You may run fixture tests and
read the diff/surrounding code. Do not inspect sibling run directories, private
measurement manifests, or ground truth. Do not invoke another review skill or CLI.
Finish only after all dispatched agents complete and findings are synthesized.
Use ordinary messages for progress/final reports. No permission is needed for this review.
'''
    (run / 'prompt.txt').write_text(prompt)
    (run / 'fixture.json').write_text(json.dumps({
        'case': case, 'variant': variant, 'repetition': repetition,
        'base': base, 'head': head,
        'diff_sha256': hashlib.sha256(diff.encode()).hexdigest(),
    }, indent=2))
    return run, workspace, prompt


def execute(root, fixture_root, case, variant, repetition, timeout):
    run, workspace, prompt = prepare(root, fixture_root, case, variant, repetition)
    command = ['codex', 'exec', '--ignore-user-config', '--json',
               '-m', 'gpt-6-luna', '-c', 'model_reasoning_effort="medium"',
               '-c', 'features.multi_agent=true',
               '-c', 'features.skip_host_skill_discovery=true',
               '-c', 'agents.max_threads=6', '-c', 'approval_policy="never"',
               '-s', 'danger-full-access', '-C', str(workspace),
               '-o', str(run / 'final.md'), '-']
    (run / 'command.json').write_text(json.dumps(command, indent=2))
    started = dt.datetime.now(dt.timezone.utc).isoformat()
    before = time.monotonic()
    env = dict(os.environ, PYTHONDONTWRITEBYTECODE='1')
    timed_out = False
    with (run / 'events.jsonl').open('w') as output, (run / 'stderr.log').open('w') as error:
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=output,
                                   stderr=error, cwd=workspace, env=env, start_new_session=True)
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
    timing = {'started_at': started,
              'completed_at': dt.datetime.now(dt.timezone.utc).isoformat(),
              'duration_seconds': time.monotonic() - before,
              'exit_code': process.returncode, 'timed_out': timed_out}
    (run / 'timing.json').write_text(json.dumps(timing, indent=2))
    print(json.dumps({'run': str(run), **timing}), flush=True)
    return run


def read_events(path):
    events = []
    try:
        for line in path.read_text().splitlines():
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                pass
    except FileNotFoundError:
        pass
    return events


def session_index():
    index = {}
    sessions = Path(os.environ.get('CODEX_HOME', str(Path.home() / '.codex'))) / 'sessions'
    for path in sessions.rglob('*.jsonl'):
        try:
            with path.open() as handle:
                first = json.loads(handle.readline())
            meta = first.get('payload', {})
            if first.get('type') != 'session_meta' or not meta.get('id'):
                continue
            index[meta['id']] = (path, meta)
        except (ValueError, OSError):
            continue
    return index


def parent_id(meta):
    source = meta.get('source')
    if isinstance(source, dict):
        return source.get('subagent', {}).get('thread_spawn', {}).get('parent_thread_id')
    return None


def commands_from_tools(tools):
    """Extract literal shell commands without evaluating recorded JavaScript."""
    commands = []
    pattern = re.compile(r"cmd\s*:\s*(\"(?:\\.|[^\"\\])*\"|'(?:\\.|[^'\\])*'|`(?:\\.|[^`\\])*`)", re.DOTALL)
    for tool in tools:
        value = tool.get('arguments') or ''
        if tool['name'] == 'exec_command':
            try:
                commands.append(json.loads(value)['cmd'])
            except (ValueError, KeyError, TypeError):
                pass
        elif tool['name'] == 'exec':
            for match in pattern.finditer(str(value)):
                literal = match.group(1)
                try:
                    command = json.loads(literal) if literal[0] == '"' else ast.literal_eval(literal)
                except (ValueError, SyntaxError):
                    command = literal[1:-1]
                commands.append(command)
    return commands


def extract_agent(path, meta):
    events = read_events(path)
    usage = None
    times = []
    model = effort = None
    tools = []
    messages = []
    status = 'unknown'
    for event in events:
        payload = event.get('payload', {})
        if event.get('type') == 'turn_context':
            model = payload.get('model', model)
            effort = payload.get('effort', effort)
        if event.get('type') == 'event_msg':
            kind = payload.get('type')
            if kind == 'token_count' and payload.get('info'):
                usage = payload['info'].get('total_token_usage', usage)
            if kind in ('task_started', 'task_complete', 'turn_aborted'):
                times.append({'timestamp': event['timestamp'], 'type': kind})
                status = kind
        if event.get('type') == 'response_item':
            kind = payload.get('type')
            if kind in ('function_call', 'custom_tool_call'):
                tools.append({'name': payload.get('name'),
                              'arguments': payload.get('arguments', payload.get('input'))})
            if kind == 'message' and payload.get('role') == 'assistant':
                text = '\n'.join(c.get('text', '') for c in payload.get('content', []))
                if text:
                    messages.append({'phase': payload.get('phase'), 'text': text})
    duration = None
    starts = [t for t in times if t['type'] == 'task_started']
    ends = [t for t in times if t['type'] in ('task_complete', 'turn_aborted')]
    if starts and ends:
        duration = (dt.datetime.fromisoformat(ends[-1]['timestamp'].replace('Z', '+00:00')) -
                    dt.datetime.fromisoformat(starts[0]['timestamp'].replace('Z', '+00:00'))).total_seconds()
    turn_seconds = []
    turn_start = None
    for item in times:
        stamp = dt.datetime.fromisoformat(item['timestamp'].replace('Z', '+00:00'))
        if item['type'] == 'task_started':
            turn_start = stamp
        elif turn_start is not None:
            turn_seconds.append((stamp-turn_start).total_seconds())
            turn_start = None
    return {'id': meta['id'], 'parent_id': parent_id(meta),
            'nickname': meta.get('agent_nickname'), 'forked_from_id': meta.get('forked_from_id'),
            'agent_path': meta.get('source', {}).get('subagent', {}).get('thread_spawn', {}).get('agent_path') if isinstance(meta.get('source'), dict) else 'controller',
            'model': model, 'effort': effort, 'usage': usage,
            'duration_seconds': duration, 'active_turn_wall_seconds': sum(turn_seconds) if turn_seconds else None,
            'turns_completed': len(turn_seconds), 'status': status,
            'tool_calls': len(tools), 'tools': tools, 'commands': commands_from_tools(tools), 'messages': messages,
            'lifecycle': times}


def aggregate(root):
    index = session_index()
    summaries = []
    for timing_path in sorted((root / 'runs').rglob('timing.json')):
        run = timing_path.parent
        events = read_events(run / 'events.jsonl')
        thread = next((e['thread_id'] for e in events if e.get('type') == 'thread.started'), None)
        ids = {thread} if thread else set()
        while True:
            children = {sid for sid, (_, meta) in index.items() if parent_id(meta) in ids}
            if children <= ids:
                break
            ids |= children
        agents = [extract_agent(*index[sid]) for sid in sorted(ids) if sid in index]
        (run / 'agents.json').write_text(json.dumps(agents, indent=2))
        complete = bool(agents) and all(a['usage'] is not None and a['status'] == 'task_complete' for a in agents)
        keys = ('input_tokens', 'cached_input_tokens', 'cache_write_input_tokens',
                'output_tokens', 'reasoning_output_tokens', 'total_tokens')
        totals = {k: sum(a['usage'].get(k, 0) for a in agents) for k in keys} if complete else None
        timing = json.loads(timing_path.read_text())
        fixture = json.loads((run / 'fixture.json').read_text())
        summary = {**fixture, **timing, 'root_thread_id': thread,
                   'agent_count_including_controller': len(agents),
                   'reviewer_count': max(0, len(agents)-1),
                   'usage_complete': complete, 'usage': totals,
                   'tool_calls': sum(a['tool_calls'] for a in agents),
                   'run_dir': str(run),
                   'worktree_status_after': git(run / 'repo', 'status', '--porcelain'),
                   'models_observed': sorted({a['model'] for a in agents if a['model']}),
                   'efforts_observed': sorted({a['effort'] for a in agents if a['effort']})}
        suite_invokers = [a for a in agents if any(re.search(r'\bpython(?:3)?\b[^;\n]*\s-m\s+unittest\b', cmd) for cmd in a['commands'])]
        summary['suite_invoking_agents'] = len(suite_invokers)
        summary['suite_invocations'] = sum(bool(re.search(r'\bpython(?:3)?\b[^;\n]*\s-m\s+unittest\b', cmd)) for a in agents for cmd in a['commands'])
        summary['controller_invoked_suite'] = any(a['id'] == thread for a in suite_invokers)
        if totals:
            summary['uncached_input_tokens'] = totals['input_tokens']-totals['cached_input_tokens']
        (run / 'summary.json').write_text(json.dumps(summary, indent=2))
        summaries.append(summary)
    valid = [r for r in summaries if r['exit_code'] == 0 and not r['timed_out'] and r['usage_complete']]
    statistics_by_variant = {}
    for variant in ('original', 'current'):
        runs = [r for r in valid if r['variant'] == variant]
        if not runs:
            continue
        durations = [r['duration_seconds'] for r in runs]
        statistics_by_variant[variant] = {
            'completed_reviews': len(runs),
            'wall_seconds_mean': statistics.mean(durations),
            'wall_seconds_median': statistics.median(durations),
            'wall_seconds_stddev': statistics.stdev(durations) if len(runs) > 1 else None,
            'reviewers_mean': statistics.mean(r['reviewer_count'] for r in runs),
            'tool_calls_mean': statistics.mean(r['tool_calls'] for r in runs),
            'usage_sum': {k: sum(r['usage'][k] for r in runs) for k in keys},
            'uncached_input_tokens_sum': sum(r['uncached_input_tokens'] for r in runs),
        }
    agent_rows = []
    for r in summaries:
        for a in json.loads((Path(r['run_dir']) / 'agents.json').read_text()):
            row = {k: r[k] for k in ('case', 'variant', 'repetition')}
            row.update({k: a.get(k) for k in ('id', 'parent_id', 'agent_path', 'nickname', 'model', 'effort', 'duration_seconds', 'active_turn_wall_seconds', 'turns_completed', 'status', 'tool_calls')})
            row.update(a['usage'] or {k: None for k in keys})
            agent_rows.append(row)
    if agent_rows:
        with (root / 'agents.csv').open('w') as handle:
            writer = csv.DictWriter(handle, fieldnames=list(agent_rows[0]))
            writer.writeheader()
            writer.writerows(agent_rows)
    (root / 'benchmark.json').write_text(json.dumps({'runs': summaries, 'statistics': statistics_by_variant}, indent=2))
    return summaries


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--fixtures', type=Path, default=Path(__file__).parent / 'fixtures/measurement')
    parser.add_argument('--cases', nargs='*')
    parser.add_argument('--original-ref', default='HEAD')
    parser.add_argument('--baseline-skill', type=Path, help='Freeze a previous skill folder instead of Git HEAD')
    parser.add_argument('--candidate-skill', type=Path, help='Freeze a candidate folder instead of current source')
    parser.add_argument('--repeat', type=int, default=1)
    parser.add_argument('--timeout', type=int, default=600)
    parser.add_argument('--aggregate-only', action='store_true')
    args = parser.parse_args()
    if not args.aggregate_only:
        snapshots(args.output, args.original_ref, args.baseline_skill, args.candidate_skill)
        for case in args.cases or sorted(p.name for p in args.fixtures.iterdir() if p.is_dir()):
            # Alternate launch order by repetition; both variants run concurrently.
            variants = ['original', 'current'] if args.repeat % 2 else ['current', 'original']
            with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
                jobs = [pool.submit(execute, args.output, args.fixtures, case, v,
                                    args.repeat, args.timeout) for v in variants]
                completed = [job.result() for job in concurrent.futures.as_completed(jobs)]
            aggregate(args.output)
            if any(json.loads((run / 'timing.json').read_text())['exit_code'] != 0 for run in completed):
                raise RuntimeError('A paired run failed; stopped before starting more cases. Preserve/exclude failed runs before retrying.')
    else:
        aggregate(args.output)


if __name__ == '__main__':
    main()
