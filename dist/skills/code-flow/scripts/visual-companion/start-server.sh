#!/usr/bin/env bash
# Bash required: uses [[ ]], local, process substitution, and OS-detection (is_windows_like_shell)
# Start the brainstorm server and output connection info
# Usage: start-server.sh [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
#
# Starts server on a random high port, outputs JSON with URL.
# Each session gets its own directory to avoid conflicts.
#
# Options:
#   --host <bind-host>    Host/interface to bind (default: 127.0.0.1).
#                         Use 0.0.0.0 in remote/containerized environments.
#   --url-host <host>     Hostname shown in returned URL JSON.
#   --idle-timeout-minutes <n>  Shut down after n minutes idle (default 240 = 4h).
#   --open                Auto-open the browser on the first screen (use only
#                         after the user approves the visual companion).
#   --foreground          Run server in the current terminal (no backgrounding).
#   --background          Run detached (the default; retained as an explicit alias).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Parse arguments
FOREGROUND="false"
FORCE_BACKGROUND="false"
BIND_HOST="127.0.0.1"
URL_HOST=""
IDLE_TIMEOUT_MINUTES=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      [[ $# -ge 2 ]] || {
        echo '{"error": "--host requires a value"}'
        exit 1
      }
      BIND_HOST="$2"
      shift 2
      ;;
    --url-host)
      [[ $# -ge 2 ]] || {
        echo '{"error": "--url-host requires a value"}'
        exit 1
      }
      URL_HOST="$2"
      shift 2
      ;;
    --idle-timeout-minutes)
      [[ $# -ge 2 ]] || {
        echo '{"error": "--idle-timeout-minutes requires a value"}'
        exit 1
      }
      IDLE_TIMEOUT_MINUTES="$2"
      shift 2
      ;;
    --open)
      export SESSION_OPEN=1
      shift
      ;;
    --foreground | --no-daemon)
      FOREGROUND="true"
      shift
      ;;
    --background | --daemon)
      FORCE_BACKGROUND="true"
      shift
      ;;
    *)
      echo "{\"error\": \"Unknown argument: $1\"}"
      exit 1
      ;;
  esac
done

if [[ -z "$URL_HOST" ]]; then
  if [[ "$BIND_HOST" == "127.0.0.1" || "$BIND_HOST" == "localhost" ]]; then
    URL_HOST="localhost"
  else
    URL_HOST="$BIND_HOST"
  fi
fi

if [[ -n "$IDLE_TIMEOUT_MINUTES" ]]; then
  if ! [[ "$IDLE_TIMEOUT_MINUTES" =~ ^[0-9]+$ ]] || [[ "$IDLE_TIMEOUT_MINUTES" -lt 1 ]]; then
    echo "{\"error\": \"--idle-timeout-minutes must be a positive integer\"}"
    exit 1
  fi
  export SESSION_IDLE_TIMEOUT_MS=$((IDLE_TIMEOUT_MINUTES * 60 * 1000))
fi

is_windows_like_shell() {
  case "${OSTYPE:-}" in
    msys* | cygwin* | mingw*) return 0 ;;
  esac
  if [[ -n "${MSYSTEM:-}" ]]; then
    return 0
  fi
  local uname_s
  uname_s="$(uname -s 2> /dev/null || true)"
  case "$uname_s" in
    MSYS* | MINGW* | CYGWIN*) return 0 ;;
  esac
  return 1
}

# A generic runner expects this command to return its connection JSON. Keep
# detached mode as the default; callers that need lifecycle ownership can opt
# into --foreground explicitly. `--background` remains a compatibility alias.

# Session files (server.log, server-info, .last-token) embed the session key —
# keep everything this script and the server create owner-only.
umask 077

# Generate unique session directory with random component
SESSION_ID="$$-$(date +%s)-${RANDOM:-0}${RANDOM:-0}"

SESSION_DIR="${TMPDIR:-/tmp}/code-flow-brainstorm-${SESSION_ID}"

STATE_DIR="${SESSION_DIR}/state"
PID_FILE="${STATE_DIR}/server.pid"
LOG_FILE="${STATE_DIR}/server.log"
SERVER_ID_FILE="${STATE_DIR}/server-instance-id"

# Create fresh session directory with content and state peers
mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"

SERVER_ID=""
if [[ -r /dev/urandom ]]; then
  SERVER_ID="$(od -An -N24 -tx1 /dev/urandom 2> /dev/null | tr -d ' \n' || true)"
fi
if ! [[ "$SERVER_ID" =~ ^[A-Za-z0-9_-]{32,64}$ ]]; then
  SERVER_ID="$(printf '%08x%08x%08x%08x' "$$" "$(date +%s)" "${RANDOM:-0}" "${RANDOM:-0}")"
fi
printf '%s\n' "$SERVER_ID" > "$SERVER_ID_FILE"
chmod 600 "$SERVER_ID_FILE" 2> /dev/null || true

# Kill any existing server
if [[ -f "$PID_FILE" ]]; then
  old_pid=$(cat "$PID_FILE")
  kill "$old_pid" 2> /dev/null
  rm -f "$PID_FILE"
fi

cd "$SCRIPT_DIR" || exit 1

# Resolve the harness PID (grandparent of this script).
# $PPID is the ephemeral shell the harness spawned to run us — it dies
# when this script exits. The harness itself is $PPID's parent.
OWNER_PID="$(ps -o ppid= -p "$PPID" 2> /dev/null | tr -d ' ')"
if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
  OWNER_PID="$PPID"
fi

# Windows/MSYS2: Node.js cannot see POSIX PIDs from the MSYS2 namespace.
# Passing a PID node cannot verify causes server to log owner-pid-invalid
# and self-terminate at the 60-second lifecycle check. Clear it so the
# lifecycle monitor is disabled and the idle timeout becomes the only shutdown trigger.
if is_windows_like_shell; then
  OWNER_PID=""
fi

# Foreground mode for environments that reap detached/background processes.
if [[ "$FOREGROUND" == "true" ]]; then
  env SESSION_DIR="$SESSION_DIR" SESSION_HOST="$BIND_HOST" SESSION_URL_HOST="$URL_HOST" SESSION_OWNER_PID="$OWNER_PID" node server.cjs "--session-server-id=$SERVER_ID" &
  SERVER_PID=$!
  echo "$SERVER_PID" > "$PID_FILE"
  wait "$SERVER_PID"
  exit $?
fi

# Start server, capturing output to log file
# Use nohup to survive shell exit; disown to remove from job table
nohup env SESSION_DIR="$SESSION_DIR" SESSION_HOST="$BIND_HOST" SESSION_URL_HOST="$URL_HOST" SESSION_OWNER_PID="$OWNER_PID" node server.cjs "--session-server-id=$SERVER_ID" > "$LOG_FILE" 2>&1 &
SERVER_PID=$!
disown "$SERVER_PID" 2> /dev/null
echo "$SERVER_PID" > "$PID_FILE"

# Wait for server-started message (check log file)
for _ in {1..50}; do
  if grep -q "server-started" "$LOG_FILE" 2> /dev/null; then
    # Extract port from log line
    server_line=$(grep "server-started" "$LOG_FILE" | head -1)
    server_port=$(echo "$server_line" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['port'])" 2> /dev/null || true)
    if [[ -n "$server_port" ]]; then
      # The start record owns the authoritative session URL (including its
      # key). Do not rely on an unset shell TOKEN or test an unauthenticated
      # route, which would only prove the authorization gate returns 403.
      server_url=$(echo "$server_line" | python3 -c 'import json, sys; from urllib.parse import urlsplit; record = json.load(sys.stdin); url = urlsplit(record["url"]); print("http://{}:{}{}?{}".format(sys.argv[1], record["port"], url.path, url.query))' "$BIND_HOST" 2> /dev/null || true)
      health_result=$(curl -s -o /dev/null -w "%{http_code}" "$server_url" 2> /dev/null || true)
      if [[ "$health_result" != "200" ]]; then
        # Wait a bit and retry once
        sleep 0.5
        health_result=$(curl -s -o /dev/null -w "%{http_code}" "$server_url" 2> /dev/null || true)
      fi
      if [[ "$health_result" != "200" ]]; then
        echo "{\"error\": \"Server started but health check failed (HTTP $health_result). Retry with: $SCRIPT_DIR/start-server.sh --host $BIND_HOST --url-host $URL_HOST --foreground\"}"
        exit 1
      fi
    fi
    # Verify server is still alive after a short window (catches process reapers)
    alive="true"
    for _ in {1..20}; do
      if ! kill -0 "$SERVER_PID" 2> /dev/null; then
        alive="false"
        break
      fi
      sleep 0.1
    done
    if [[ "$alive" != "true" ]]; then
      echo "{\"error\": \"Server started but was killed. Retry in a persistent terminal with: $SCRIPT_DIR/start-server.sh --host $BIND_HOST --url-host $URL_HOST --foreground\"}"
      exit 1
    fi
    echo "$server_line"
    exit 0
  fi
  sleep 0.1
done

# Timeout - server didn't start
echo '{"error": "Server failed to start within 5 seconds"}'
exit 1
