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
expected=$(printf '%s\n' 01-dispatcher.md 02-architect.md 03-executor.md 04-code-reviewer.md 05-integrator.md)
[[ "$agents" == "$expected" ]] || fail "unexpected agents: $agents"

templates=$(find "$ROOT/templates" -maxdepth 1 -name '*.md' -printf '%f\n' | sort)
expected=$(printf '%s\n' architecture-review-template.md delivery-review-template.md evidence-template.md \
  follow-up-issue-template.md human-gate-template.md implementation-evidence-template.md \
  integration-report-template.md issue-template.md operational-note-template.md)
[[ "$templates" == "$expected" ]] || fail "unexpected templates: $templates"

[[ ! -d "$ROOT/phases" && ! -d "$ROOT/references" && ! -d "$ROOT/dev" && ! -d "$ROOT/evals" ]] || fail 'old directories remain'
[[ -f "$ROOT/runtime.md" && -f "$ROOT/workflow-states.json" ]] || fail 'root contracts missing'
[[ $(wc -l < "$ROOT/SKILL.md") -le 50 ]] || fail 'SKILL.md exceeds 50 lines'
has '/code-flow <issue>' "$ROOT/SKILL.md"
has '/code-flow doctor [args]' "$ROOT/SKILL.md"
lacks '/code-flow batch' "$ROOT/SKILL.md"
lacks '/code-flow tool doctor' "$ROOT/SKILL.md"
lacks 'protocol_version' "$ROOT/runtime.md"
lacks 'lease_ttl' "$ROOT/runtime.md"
has 'XS/S sem hard trigger' "$ROOT/runtime.md"
has 'stage:needs-architect' "$ROOT/agents/03-executor.md"
has 'instância nova' "$ROOT/agents/04-code-reviewer.md"

jq -e '
  (.schema_version == null) and (.legacy == null) and (.states|length == 10) and
  (.states[]|select(.label=="stage:needs-triage")|.actor=="dispatcher") and
  (.states[]|select(.label=="stage:needs-delivery-review")|.actor=="code-reviewer") and
  (.states[]|select(.label=="stage:ready-for-execution")|.next|index("stage:needs-architect")!=null) and
  (.states[]|select(.label=="stage:needs-changes")|.next|index("stage:needs-architect")!=null)
' "$ROOT/workflow-states.json" > /dev/null || fail 'invalid registry'

for template in architecture-review-template.md delivery-review-template.md evidence-template.md \
  human-gate-template.md implementation-evidence-template.md integration-report-template.md \
  operational-note-template.md; do
  for field in agent run_id event state_before state_after sources_evidence project_guidance; do
    grep -Eq "^> $field:" "$ROOT/templates/$template" || fail "$template missing $field"
  done
  grep -Eq '^## Resume$' "$ROOT/templates/$template" || fail "$template missing Resume"
  lacks 'protocol_version' "$ROOT/templates/$template"
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

for script in "$ROOT"/scripts/*.sh; do bash -n "$script"; done
jq -e '.skill_name=="code-flow" and (.evals|length>=5)' "$ROOT/tests/evals/evals.json" > /dev/null
[[ -f "$ROOT/tests/evals/run-evals.mjs" && -f "$ROOT/tests/evals/fixtures/e5-agents-md/AGENTS.md" ]] || fail 'eval files missing'

printf 'PASS: code-flow tests\n'
