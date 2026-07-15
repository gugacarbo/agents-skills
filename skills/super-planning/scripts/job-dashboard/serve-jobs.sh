#!/usr/bin/env bash
# Start or stop the read-only super-planning jobs dashboard.
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SERVER="$SCRIPT_DIR/server.cjs"
PROJECT_DIR="$(pwd -P)"
BASE_ARG=""
HOST="0.0.0.0"
URL_HOST=""
PORT=""
REFRESH_MS=1000
FOREGROUND=false
OPEN=false
STOP=false

usage() {
  cat >&2 <<'EOF'
Usage: serve-jobs.sh [--project-dir <path>] [--base-dir <path>] [--host <host>]
                     [--url-host <host>] [--port <port>] [--refresh-ms <ms>]
                     [--foreground] [--open]
       serve-jobs.sh --stop [--project-dir <path>]
EOF
}

fail() { printf 'job dashboard: %s\n' "$*" >&2; exit 1; }

canonical_dir() { CDPATH='' cd -- "$1" 2>/dev/null && pwd -P; }
canonical_future_dir() {
  local current="$1" suffix="" name parent
  while [[ ! -e "$current" && ! -L "$current" ]]; do
    name=${current##*/}
    suffix="/$name$suffix"
    parent=${current%/*}
    [[ -n "$parent" ]] || parent="/"
    [[ "$parent" != "$current" ]] || return 1
    current="$parent"
  done
  [[ -d "$current" ]] || return 1
  current=$(canonical_dir "$current") || return 1
  printf '%s%s\n' "$current" "$suffix"
}
random_hex() { od -An -N32 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir|--base-dir|--host|--url-host|--port|--refresh-ms)
      [[ $# -ge 2 ]] || fail "$1 requires a value"
      case "$1" in
        --project-dir) PROJECT_DIR="$2" ;;
        --base-dir) BASE_ARG="$2" ;;
        --host) HOST="$2" ;;
        --url-host) URL_HOST="$2" ;;
        --port) PORT="$2" ;;
        --refresh-ms) REFRESH_MS="$2" ;;
      esac
      shift 2 ;;
    --foreground) FOREGROUND=true; shift ;;
    --open) OPEN=true; shift ;;
    --stop) STOP=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
done

PROJECT_DIR=$(canonical_dir "$PROJECT_DIR") || fail "project directory not found: $PROJECT_DIR"
if [[ -z "$BASE_ARG" ]]; then BASE_ARG="$PROJECT_DIR/docs/jobs"; fi
if [[ "$BASE_ARG" != /* ]]; then BASE_ARG="$PROJECT_DIR/$BASE_ARG"; fi
if [[ "$STOP" == true ]]; then
  BASE_DIR=$(canonical_future_dir "$BASE_ARG") || fail "could not resolve jobs root: $BASE_ARG"
else
  BASE_DIR=$(canonical_dir "$BASE_ARG") || fail "jobs root not found: $BASE_ARG"
fi
[[ -f "$SERVER" ]] || fail "dashboard server is missing: $SERVER"
command -v node >/dev/null 2>&1 || fail "node.js 18 or newer is required"
node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)' || fail "node.js 18 or newer is required"
[[ "$REFRESH_MS" =~ ^[0-9]+$ ]] && (( REFRESH_MS >= 250 )) || fail "--refresh-ms must be an integer of at least 250"
if [[ -n "$PORT" ]]; then
  [[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) || fail "--port must be an integer from 1 to 65535"
fi
if [[ -z "$URL_HOST" ]]; then
  if [[ "$HOST" == "0.0.0.0" || "$HOST" == "::" ]]; then
    URL_HOST=$(node -e 'const os=require("node:os"); const all=Object.values(os.networkInterfaces()).flat().filter((x)=>x && !x.internal); const pick=all.find((x)=>x.family==="IPv4") || all[0]; process.stdout.write(pick ? pick.address : "localhost");')
  else
    URL_HOST="$HOST"
  fi
fi

STATE_DIR=$(canonical_future_dir "$PROJECT_DIR/.super-planning/job-dashboard") || fail "could not resolve runtime state directory"
STATE_PARENT="$PROJECT_DIR/.super-planning"
STATE_REQUESTED_DIR="$STATE_PARENT/job-dashboard"
if [[ "$STATE_DIR" != "$PROJECT_DIR" && "$STATE_DIR" != "$PROJECT_DIR"/* ]]; then
  fail "runtime state directory must remain inside project directory: $STATE_DIR"
fi
if [[ "$STATE_DIR" == "$BASE_DIR" || "$STATE_DIR" == "$BASE_DIR"/* ]]; then
  fail "runtime state directory must not be inside jobs root: $STATE_DIR"
fi
PID_FILE="$STATE_DIR/server.pid"
INFO_FILE="$STATE_DIR/server-info.json"
TOKEN_FILE="$STATE_DIR/session-token"
INSTANCE_FILE="$STATE_DIR/server-instance-id"
LOCK_FILE="$STATE_DIR/start.lock"
LOCK_FD=""
LOCK_HELD=false

# Runtime state is private process-control data.  Do not accept a symlink at
# any point in this path: shell redirections otherwise follow it and could
# overwrite an arbitrary file.  Atomic replacement below also means a target
# swapped for a symlink after this check is replaced, never followed.
assert_state_dir_path() {
  [[ ! -L "$STATE_PARENT" && ! -L "$STATE_REQUESTED_DIR" ]] || fail "runtime state directory must not contain symlinks"
  [[ ! -e "$STATE_PARENT" || -d "$STATE_PARENT" ]] || fail "runtime state parent must be a directory"
  [[ ! -e "$STATE_REQUESTED_DIR" || -d "$STATE_REQUESTED_DIR" ]] || fail "runtime state directory must be a directory"
  [[ ! -L "$STATE_DIR" && (! -e "$STATE_DIR" || -d "$STATE_DIR") ]] || fail "runtime state directory must not be a symlink"
}

assert_state_file_safe() {
  local file="$1"
  [[ ! -L "$file" ]] || fail "runtime state file must not be a symlink: ${file##*/}"
  [[ ! -e "$file" || -f "$file" ]] || fail "runtime state file must be a regular file: ${file##*/}"
}

assert_runtime_files_safe() {
  assert_state_dir_path
  local file
  for file in "$PID_FILE" "$INFO_FILE" "$TOKEN_FILE" "$INSTANCE_FILE" "$LOCK_FILE" "$STATE_DIR/server.log"; do
    assert_state_file_safe "$file"
  done
}

ensure_state_dir() {
  assert_state_dir_path
  (umask 077; mkdir -p -- "$STATE_DIR") || fail "could not create runtime state directory"
  assert_state_dir_path
}

atomic_write_state() {
  local file="$1" value="$2" tmp
  assert_state_dir_path
  assert_state_file_safe "$file"
  tmp=$(mktemp "$STATE_DIR/.${file##*/}.tmp.XXXXXX") || fail "could not create runtime state temporary file"
  chmod 600 "$tmp" 2>/dev/null || true
  if ! printf '%s' "$value" > "$tmp"; then
    rm -f -- "$tmp"
    fail "could not write runtime state temporary file"
  fi
  # rename(2) replaces a symlink itself rather than following it.
  mv -f -- "$tmp" "$file" || { rm -f -- "$tmp"; fail "could not replace runtime state file: ${file##*/}"; }
}

remove_state_files() {
  local file
  for file in "$@"; do assert_state_file_safe "$file"; done
  rm -f -- "$@"
}

release_lock() {
  if [[ "$LOCK_HELD" == true ]]; then
    flock -u "$LOCK_FD" 2>/dev/null || true
    LOCK_HELD=false
  fi
}

acquire_lock() {
  command -v flock >/dev/null 2>&1 || fail "flock is required for safe dashboard lifecycle locking"
  assert_state_dir_path
  assert_state_file_safe "$LOCK_FILE"
  if [[ ! -e "$LOCK_FILE" ]]; then
    local tmp
    tmp=$(mktemp "$STATE_DIR/.start.lock.tmp.XXXXXX") || fail "could not create dashboard lifecycle lock"
    chmod 600 "$tmp" 2>/dev/null || true
    if ! ln "$tmp" "$LOCK_FILE" 2>/dev/null; then
      rm -f -- "$tmp"
      assert_state_file_safe "$LOCK_FILE"
      [[ -f "$LOCK_FILE" ]] || fail "could not create dashboard lifecycle lock"
    else
      rm -f -- "$tmp"
    fi
  fi
  # flock is advisory and works with a read-only descriptor.  Keeping this
  # descriptor read-only avoids a lock-file write that could follow a link.
  exec {LOCK_FD}<"$LOCK_FILE" || fail "could not open dashboard lifecycle lock"
  flock -w 10 "$LOCK_FD" || fail "timed out waiting for another dashboard start or stop"
  LOCK_HELD=true
}

url_host() {
  if [[ "$1" == *:* && "$1" != \[*\] ]]; then printf '[%s]' "$1"; else printf '%s' "$1"; fi
}

health_host() {
  case "$1" in
    0.0.0.0) printf '%s' '127.0.0.1' ;;
    ::) printf '%s' '::1' ;;
    *) printf '%s' "$1" ;;
  esac
}

dashboard_url() { printf 'http://%s:%s/?key=%s' "$(url_host "$URL_HOST")" "$1" "$TOKEN"; }
health_url() { printf 'http://%s:%s/healthz?key=%s' "$(url_host "$(health_host "$1")")" "$2" "$3"; }
probe_health() { local host="${3:-$HOST}"; curl --noproxy '*' -fsS --max-time 2 "$(health_url "$host" "$1" "$2")" >/dev/null 2>&1; }

pid_matches_instance() {
  local pid="$1" instance="$2" args
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  # An empty instance ID would make the command-line check below match every
  # valid --instance-id=<value> argument by prefix.  Lifecycle actions must
  # fail closed until all of their process-identity proof is well formed.
  [[ "$instance" =~ ^[0-9a-f]{64}$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  args=$(ps -o args= -p "$pid" 2>/dev/null || true)
  [[ "$args" == *"$SERVER"* && "$args" == *"--instance-id=$instance"* ]]
}

clear_live_metadata() { remove_state_files "$PID_FILE" "$INFO_FILE" "$INSTANCE_FILE"; }

remove_original_launch_metadata() {
  # This runs only while the lifecycle lock is held after a child-start
  # failure.  Each file is independently removed only when its own contents
  # prove it belongs to the launch that failed.  A later helper may have
  # already published a successor by the time this helper reacquires the lock.
  local expected_pid="$1" expected_instance="$2" current
  if [[ -f "$PID_FILE" ]]; then
    current=$(tr -d '[:space:]' < "$PID_FILE")
    [[ "$current" == "$expected_pid" ]] && remove_state_files "$PID_FILE"
  fi
  if [[ -f "$INSTANCE_FILE" ]]; then
    current=$(tr -d '[:space:]' < "$INSTANCE_FILE")
    [[ "$current" == "$expected_instance" ]] && remove_state_files "$INSTANCE_FILE"
  fi
  if [[ -f "$INFO_FILE" ]] && node - "$INFO_FILE" "$expected_pid" "$expected_instance" <<'NODE'
const [file, pid, instance] = process.argv.slice(2);
try {
  const info = JSON.parse(require("node:fs").readFileSync(file, "utf8"));
  process.exit(info && String(info.pid) === pid && info.instanceId === instance ? 0 : 1);
} catch (_) { process.exit(1); }
NODE
  then
    remove_state_files "$INFO_FILE"
  fi
}

wait_for_test_failure_cleanup_release() {
  # This narrow test gate makes the post-handoff successor race repeatable.
  # It is intentionally private runtime state and has no user-facing effect.
  [[ "${DASHBOARD_TEST_PAUSE_BEFORE_FAILURE_CLEANUP:-}" == 1 ]] || return 0
  local ready="$STATE_DIR/.test-before-failure-cleanup-ready"
  local release="$STATE_DIR/.test-before-failure-cleanup-release"
  atomic_write_state "$ready" "$$"$'\n'
  while [[ ! -e "$release" ]]; do sleep 0.01; done
  assert_state_file_safe "$release"
  remove_state_files "$ready" "$release"
}

cleanup_failed_launch() {
  local expected_pid="$1" expected_instance="$2"
  # The child inherited and then released our lock.  Reacquire it before
  # inspecting metadata: a successor may have won the lifecycle race.
  acquire_lock
  assert_runtime_files_safe
  remove_original_launch_metadata "$expected_pid" "$expected_instance"
  release_lock
}

handoff_lock_to_server() {
  # flock locks belong to the inherited open-file description.  Closing only
  # the helper's descriptor leaves the child holding the lock until it has
  # published and validated its own runtime metadata.  Do not use flock -u:
  # that would release the shared lock for both processes.
  [[ "$LOCK_HELD" == true ]] || return 0
  eval "exec ${LOCK_FD}>&-"
  LOCK_HELD=false
  LOCK_FD=""
}

if [[ "$STOP" == true ]]; then
  if [[ ! -d "$STATE_DIR" ]]; then
    printf '%s\n' '{"type":"job-dashboard-stopped","status":"not_running"}'
    exit 0
  fi
  assert_runtime_files_safe
  trap release_lock EXIT
  acquire_lock
  assert_runtime_files_safe
  if [[ ! -f "$PID_FILE" ]]; then
    printf '%s\n' '{"type":"job-dashboard-stopped","status":"not_running"}'
    exit 0
  fi
  old_pid=$(tr -d '[:space:]' < "$PID_FILE")
  old_instance=$(tr -d '[:space:]' < "$INSTANCE_FILE" 2>/dev/null || true)
  if ! pid_matches_instance "$old_pid" "$old_instance"; then
    clear_live_metadata
    printf '%s\n' '{"type":"job-dashboard-stopped","status":"stale_pid"}'
    exit 0
  fi
  kill "$old_pid" 2>/dev/null || true
  for _ in $(seq 1 30); do kill -0 "$old_pid" 2>/dev/null || break; sleep 0.1; done
  kill -0 "$old_pid" 2>/dev/null && fail "dashboard process did not stop: $old_pid"
  clear_live_metadata
  printf '%s\n' '{"type":"job-dashboard-stopped","status":"stopped"}'
  exit 0
fi

ensure_state_dir
trap release_lock EXIT
acquire_lock
assert_runtime_files_safe

if [[ -f "$PID_FILE" && -f "$INFO_FILE" && -f "$TOKEN_FILE" && -f "$INSTANCE_FILE" ]]; then
  old_pid=$(tr -d '[:space:]' < "$PID_FILE")
  old_instance=$(tr -d '[:space:]' < "$INSTANCE_FILE")
  if pid_matches_instance "$old_pid" "$old_instance"; then
    old_port=$(node -e 'try { const x=require(process.argv[1]); process.stdout.write(String(x.port || "")); } catch (_) {}' "$INFO_FILE")
    old_host=$(node -e 'try { const x=require(process.argv[1]); process.stdout.write(String(x.host || "")); } catch (_) {}' "$INFO_FILE")
    old_url_host=$(node -e 'try { const x=require(process.argv[1]); process.stdout.write(String(x.urlHost || "")); } catch (_) {}' "$INFO_FILE")
    old_base_dir=$(node -e 'try { const x=require(process.argv[1]); process.stdout.write(String(x.baseDir || "")); } catch (_) {}' "$INFO_FILE")
    token=$(tr -d '[:space:]' < "$TOKEN_FILE")
    if [[ "$old_port" =~ ^[0-9]+$ && -n "$old_host" && -n "$old_base_dir" ]] && probe_health "$old_port" "$token" "$old_host"; then
      [[ -n "$old_url_host" ]] || old_url_host="$old_host"
      node - "$old_pid" "$old_port" "$old_url_host" "$PROJECT_DIR" "$old_base_dir" "$STATE_DIR" "$token" <<'NODE'
const [pid, port, host, project, base, state, token] = process.argv.slice(2);
const displayHost = host.includes(':') && !host.startsWith('[') ? `[${host}]` : host;
console.log(JSON.stringify({type:'job-dashboard-started', pid:Number(pid), port:Number(port), url:`http://${displayHost}:${port}/?key=${token}`, project_dir:project, base_dir:base, state_dir:state}));
NODE
      exit 0
    fi
  fi
  clear_live_metadata
fi

if [[ -f "$TOKEN_FILE" ]]; then
  TOKEN=$(tr -d '[:space:]' < "$TOKEN_FILE")
else
  TOKEN=$(random_hex)
  [[ "$TOKEN" =~ ^[0-9a-f]{64}$ ]] || fail "could not generate session token"
  atomic_write_state "$TOKEN_FILE" "$TOKEN"$'\n'
fi
INSTANCE_ID=$(random_hex)
[[ "$INSTANCE_ID" =~ ^[0-9a-f]{64}$ ]] || fail "could not generate instance id"
remove_state_files "$INFO_FILE" "$PID_FILE" "$INSTANCE_FILE"

# The child inherits the locked descriptor.  It writes its own PID, instance
# ID, and server info before releasing it, closing the crash window between
# spawn and server.pid publication.
launch=(env "DASHBOARD_LIFECYCLE_LOCK_FD=$LOCK_FD" "DASHBOARD_PROJECT_DIR=$PROJECT_DIR" "DASHBOARD_BASE_DIR=$BASE_DIR" "DASHBOARD_STATE_DIR=$STATE_DIR" "DASHBOARD_TOKEN=$TOKEN" "DASHBOARD_HOST=$HOST" "DASHBOARD_URL_HOST=$URL_HOST" "DASHBOARD_PORT=${PORT:-0}" "DASHBOARD_REFRESH_MS=$REFRESH_MS" node "$SERVER" "--instance-id=$INSTANCE_ID")
LOG_FILE="$STATE_DIR/server.log"
if [[ "$FOREGROUND" == true ]]; then
  "${launch[@]}" &
else
  # server.cjs writes its own owner-only log atomically.  Keeping nohup output
  # off the state path avoids a shell redirection that could follow a symlink.
  nohup "${launch[@]}" </dev/null >/dev/null 2>&1 &
fi
SERVER_PID=$!
handoff_lock_to_server

for _ in $(seq 1 50); do
  if [[ -f "$INFO_FILE" ]]; then
    bound_port=$(node -e 'try { const x=require(process.argv[1]); process.stdout.write(String(x.port || "")); } catch (_) {}' "$INFO_FILE")
    if [[ "$bound_port" =~ ^[0-9]+$ ]] && probe_health "$bound_port" "$TOKEN"; then
      if [[ "$FOREGROUND" == true ]]; then
        release_lock
        wait "$SERVER_PID"
        exit $?
      fi
      node - "$SERVER_PID" "$bound_port" "$URL_HOST" "$PROJECT_DIR" "$BASE_DIR" "$STATE_DIR" "$TOKEN" <<'NODE'
const [pid, port, host, project, base, state, token] = process.argv.slice(2);
const displayHost = host.includes(':') && !host.startsWith('[') ? `[${host}]` : host;
console.log(JSON.stringify({type:'job-dashboard-started', pid:Number(pid), port:Number(port), url:`http://${displayHost}:${port}/?key=${token}`, project_dir:project, base_dir:base, state_dir:state}));
NODE
      if [[ "$OPEN" == true ]]; then
        if command -v xdg-open >/dev/null 2>&1; then xdg-open "$(dashboard_url "$bound_port")" >/dev/null 2>&1 || printf 'job dashboard: could not open browser\n' >&2
        else printf 'job dashboard: no supported browser opener\n' >&2; fi
      fi
      exit 0
    fi
  fi
  kill -0 "$SERVER_PID" 2>/dev/null || {
    wait_for_test_failure_cleanup_release
    cleanup_failed_launch "$SERVER_PID" "$INSTANCE_ID"
    fail "server failed to start; see $LOG_FILE"
  }
  sleep 0.1
done
kill "$SERVER_PID" 2>/dev/null || true
wait_for_test_failure_cleanup_release
cleanup_failed_launch "$SERVER_PID" "$INSTANCE_ID"
fail "server did not become healthy; see $LOG_FILE"
