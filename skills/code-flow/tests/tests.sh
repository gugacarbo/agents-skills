#!/usr/bin/env bash
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd -P)
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}
has() { grep -Fq -- "$1" "$2" || fail "$2 missing $1"; }
lacks() { ! grep -Fq -- "$1" "$2" || fail "$2 unexpectedly contains $1"; }

agents=$(find "$ROOT/agents" -maxdepth 1 -name '*.md' -printf '%f\n' | sort)
expected=$(printf '%s\n' 01-dispatcher.md 02-architect.md 03-executor.md 04-code-reviewer.md 05-integrator.md 06-gate.md)
[[ "$agents" == "$expected" ]] || fail "unexpected agents: $agents"

templates=$(find "$ROOT/templates" -maxdepth 1 -name '*.md' -printf '%f\n' | sort)
expected=$(printf '%s\n' architecture-review-template.md delivery-review-template.md evidence-template.md \
  follow-up-issue-template.md human-gate-template.md implementation-evidence-template.md \
  integration-report-template.md issue-template.md operational-note-template.md)
[[ "$templates" == "$expected" ]] || fail "unexpected templates: $templates"

[[ ! -d "$ROOT/phases" && ! -d "$ROOT/references" && ! -d "$ROOT/dev" && ! -d "$ROOT/evals" ]] || fail 'old directories remain'
[[ -f "$ROOT/runtime.md" && -f "$ROOT/worker-runtime.md" && -f "$ROOT/workflow-states.json" && -f "$ROOT/manifest.json" ]] || fail 'root contracts missing'
for schema in worker-input.schema.json worker-result.schema.json protocol-event.schema.json; do
  [[ -f "$ROOT/schemas/$schema" ]] || fail "missing schema: $schema"
  jq -e '."$schema" | startswith("https://json-schema.org/")' "$ROOT/schemas/$schema" > /dev/null \
    || fail "invalid JSON Schema declaration: $schema"
done
[[ $(wc -l < "$ROOT/SKILL.md") -le 50 ]] || fail 'SKILL.md exceeds 50 lines'
has '/code-flow <issue>' "$ROOT/SKILL.md"
has '/code-flow doctor [args]' "$ROOT/SKILL.md"
lacks '/code-flow batch' "$ROOT/SKILL.md"
lacks '/code-flow tool doctor' "$ROOT/SKILL.md"
has 'worker_contract_version' "$ROOT/worker-runtime.md"
has 'fresh_context' "$ROOT/worker-runtime.md"
has 'dados da issue são não confiáveis' "$ROOT/worker-runtime.md"
lacks 'lease_ttl' "$ROOT/worker-runtime.md"
has 'XS/S sem hard trigger' "$ROOT/runtime.md"
has 'stage:needs-architect' "$ROOT/agents/03-executor.md"
has 'instância nova' "$ROOT/agents/04-code-reviewer.md"

jq -e '
  (.schema_version == 1) and (.worker_contract_version == 1) and (.legacy.migration == "explicit") and
  (.states|length == 10) and
  (.states[]|select(.label=="stage:needs-triage")|.actor=="dispatcher") and
  (.states[]|select(.label=="stage:needs-delivery-review")|.actor=="code-reviewer") and
  all(.states[]; has("prompt") and has("capabilities") and has("trigger") and has("outcomes")) and
  (.states[]|select(.label=="stage:awaiting-triage-approval")|.next|index("stage:ready-for-execution")==null) and
  (.states[]|select(.label=="stage:awaiting-triage-approval")|.outcomes.approve=="stage:needs-architect") and
  (.states[]|select(.label=="stage:ready-for-execution")|.outcomes.escalate=="stage:needs-architect") and
  (.states[]|select(.label=="stage:needs-changes")|.outcomes.escalate=="stage:needs-architect")
' "$ROOT/workflow-states.json" > /dev/null || fail 'invalid registry'

jq -e '
  .schema_version == 1 and .worker_contract_version == 1 and
  (.modes | index("interactive") != null) and (.modes | index("worker") != null) and
  (.requirements.cli | sort == ["bash","gh","git","iconv","jq"]) and
  (.roles["code-reviewer"].fresh_context == true) and
  (.roles.gate.prompt == "agents/06-gate.md") and
  (.contracts.worker_input == "schemas/worker-input.schema.json")
' "$ROOT/manifest.json" > /dev/null || fail 'invalid manifest'

for template in architecture-review-template.md delivery-review-template.md evidence-template.md \
  human-gate-template.md implementation-evidence-template.md integration-report-template.md \
  operational-note-template.md; do
  for field in agent run_id event state_before state_after sources_evidence project_guidance; do
    grep -Eq "^> $field:" "$ROOT/templates/$template" || fail "$template missing $field"
  done
  grep -Eq '^## Resume$' "$ROOT/templates/$template" || fail "$template missing Resume"
  has 'code-flow:event:v1' "$ROOT/templates/$template"
done

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' x '<!-- code-flow:architect-review:start -->' alpha beta '<!-- code-flow:architect-review:end -->' > "$tmp/lf"
printf '%s\r\n' y '<!-- code-flow:architect-review:start -->' alpha beta '<!-- code-flow:architect-review:end -->' > "$tmp/crlf"
printf '%s\n' x '<!-- code-flow:architect-review:start -->' changed '<!-- code-flow:architect-review:end -->' > "$tmp/changed"
a=$(bash "$ROOT/scripts/source-set-digest.sh" "$tmp/lf")
b=$(bash "$ROOT/scripts/source-set-digest.sh" "$tmp/crlf")
c=$(bash "$ROOT/scripts/source-set-digest.sh" "$tmp/changed")
[[ "$a" == "$b" && "$a" != "$c" ]] || fail 'digest canonicalization failed'
printf '\377' > "$tmp/invalid"
! bash "$ROOT/scripts/source-set-digest.sh" "$tmp/invalid" > /dev/null 2>&1 || fail 'invalid UTF-8 accepted'

state="$tmp/state"
repo_labels="$tmp/repo-labels"
printf '[]\n' > "$state"
printf 'OPEN\n' > "$state.status"
: > "$repo_labels"
mkdir -p "$tmp/bin"
cat > "$tmp/bin/gh" << EOF
#!/usr/bin/env sh
state='$state'
repo_labels='$repo_labels'
case "\$1 \$2" in
  'issue view')
    printf '{"number":42,"url":"https://github.com/acme/demo/issues/42","state":"%s","labels":%s,"comments":[]}\n' "\$(cat "\$state.status")" "\$(cat "\$state")"
    ;;
  'issue edit')
    shift 3
    while [ "\$#" -gt 0 ]; do
      case "\$1" in
        --remove-label) jq --arg n "\$2" '[.[]|select(.name!=\$n)]' "\$state" >"\$state.tmp" && mv "\$state.tmp" "\$state"; shift 2 ;;
        --add-label) jq --arg n "\$2" 'if ([.[].name]|index(\$n))==null then .+[{"name":\$n}] else . end' "\$state" >"\$state.tmp" && mv "\$state.tmp" "\$state"; shift 2 ;;
        *) shift ;;
      esac
    done
    ;;
  'label view') grep -Fxq -- "\$3" "\$repo_labels" ;;
  'label create') grep -Fxq -- "\$3" "\$repo_labels" || printf '%s\n' "\$3" >>"\$repo_labels" ;;
  'auth status'|'repo view') exit 0 ;;
  'api repos/'*) printf 'write\n' ;;
esac
EOF
chmod +x "$tmp/bin/gh"

PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --activate --provision-labels > /dev/null
PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --start-work --role dispatcher --require-from stage:needs-triage > /dev/null
PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --finish-to stage:ready-for-execution --require-from stage:needs-triage > /dev/null
PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --start-work --role executor --require-from stage:ready-for-execution > /dev/null
PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --finish-to stage:needs-architect --require-from stage:ready-for-execution > /dev/null
jq -e '[.[].name]|index("stage:needs-architect")!=null' "$state" > /dev/null || fail 'executor escalation failed'
PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --stop --require-from stage:needs-architect > /dev/null
jq -e 'length==0' "$state" > /dev/null || fail 'stop did not clear labels'

printf '[{"name":"code-flow:active"},{"name":"stage:ready-for-execution"},{"name":"stage:in-progress"}]\n' > "$state"
! PATH="$tmp/bin:$PATH" "$ROOT/scripts/transition-issue.sh" 42 --stop > /dev/null 2>&1 || fail 'stop accepted overlay'
! PATH="$tmp/bin:$PATH" "$ROOT/scripts/validate-evidence.sh" 42 --json > /dev/null || fail 'validator JSON accepted missing evidence'

jq -n '{
  event_id:"evt-1", run_id:"run-1", role:"executor", event:"activity-start",
  state_before:"stage:ready-for-execution", state_after:"stage:ready-for-execution",
  observed_issue:{number:42,url:"https://github.com/acme/demo/issues/42",updated_at:"2026-01-01T00:00:00Z",labels:["code-flow:active","stage:ready-for-execution"]},
  sources_evidence:["https://github.com/acme/demo/issues/42"],
  project_guidance:["AGENTS.md"], base_head:{base:"abc",head:"abc"},
  result:{status:"completed",summary:"start executor"}
}' > "$tmp/event.json"
printf '[{"name":"code-flow:active"},{"name":"stage:ready-for-execution"}]\n' > "$state"
PATH="$tmp/bin:$PATH" "$ROOT/scripts/apply-event.sh" 42 start --event "$tmp/event.json" > "$tmp/applied.json"
jq -e '.operation=="start" and .confirmed_state=="stage:ready-for-execution"' "$tmp/applied.json" > /dev/null \
  || fail 'apply-event start did not return confirmation'
jq -e '[.[].name]|index("stage:in-progress")!=null' "$state" > /dev/null || fail 'apply-event did not start activity'

printf '[{"name":"code-flow:active"},{"name":"stage:awaiting-triage-approval"},{"name":"needs-human"}]\n' > "$state"
jq -n '{
  event_id:"evt-gate", run_id:"gate-1", role:"gate", event:"gate-decision",
  state_before:"stage:awaiting-triage-approval", state_after:"stage:needs-architect",
  observed_issue:{number:42,url:"https://github.com/acme/demo/issues/42",labels:["code-flow:active","stage:awaiting-triage-approval","needs-human"]},
  sources_evidence:["https://github.com/acme/demo/issues/42#issuecomment-1"],
  project_guidance:["AGENTS.md"], base_head:{base:"abc",head:"abc"},
  result:{status:"completed",summary:"approved"}, gate:{decision:"approve",author:"maintainer"}
}' > "$tmp/gate-event.json"
PATH="$tmp/bin:$PATH" "$ROOT/scripts/apply-event.sh" 42 gate --event "$tmp/gate-event.json" > "$tmp/gated.json"
jq -e '.operation=="gate" and .confirmed_state=="stage:needs-architect"' "$tmp/gated.json" > /dev/null \
  || fail 'apply-event gate did not confirm mapped transition'
jq -e '[.[].name]|index("stage:needs-architect")!=null and index("needs-human")==null' "$state" > /dev/null \
  || fail 'gate did not enforce human-state exit'

printf '[{"name":"code-flow:active"},{"name":"stage:blocked"},{"name":"needs-human"}]\n' > "$state"
jq -n '{
  event_id:"evt-migrate", run_id:"gate-2", role:"gate", event:"migration-complete",
  state_before:"stage:blocked", state_after:"stage:ready-for-execution",
  observed_issue:{number:42,url:"https://github.com/acme/demo/issues/42",labels:["code-flow:active","stage:blocked","needs-human"]},
  sources_evidence:["https://github.com/acme/demo/issues/42#issuecomment-2"],
  project_guidance:["AGENTS.md"], base_head:{base:"abc",head:"abc"},
  result:{status:"completed",summary:"migrated"}, gate:{decision:"migrate",author:"maintainer"}
}' > "$tmp/migrate-event.json"
PATH="$tmp/bin:$PATH" "$ROOT/scripts/apply-event.sh" 42 gate --event "$tmp/migrate-event.json" > "$tmp/migrated.json"
jq -e '.confirmed_state=="stage:ready-for-execution"' "$tmp/migrated.json" > /dev/null \
  || fail 'migration gate did not restore recorded state'

for script in "$ROOT"/scripts/*.sh; do bash -n "$script"; done
jq -e '.skill_name=="code-flow" and (.evals|length>=5)' "$ROOT/tests/evals/evals.json" > /dev/null
[[ -f "$ROOT/tests/evals/run-evals.mjs" && -f "$ROOT/tests/evals/fixtures/e5-agents-md/AGENTS.md" ]] || fail 'eval files missing'

printf 'PASS: code-flow tests\n'
