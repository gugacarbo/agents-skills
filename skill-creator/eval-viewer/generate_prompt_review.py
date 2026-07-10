#!/usr/bin/env python3
"""Generate and serve an approval page for eval prompts.

Reads an `evals/evals.json` file, embeds it into a standalone HTML page,
and optionally serves that page with save-back endpoints so the user can
edit and approve the prompt set before any eval runs begin.
"""

import argparse
import json
import os
import signal
import subprocess
import sys
import time
import webbrowser
from functools import partial
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path


def load_evals(evals_path: Path) -> dict:
    data = json.loads(evals_path.read_text())
    if not isinstance(data, dict):
        raise ValueError("evals.json must contain a JSON object")
    if "evals" not in data or not isinstance(data["evals"], list):
        raise ValueError("evals.json must contain an 'evals' array")
    return data


def validate_evals(data: dict) -> dict:
    if not isinstance(data, dict):
        raise ValueError("Expected JSON object")
    skill_name = data.get("skill_name", "")
    evals = data.get("evals")
    if not isinstance(skill_name, str) or not skill_name.strip():
        raise ValueError("skill_name must be a non-empty string")
    if not isinstance(evals, list):
        raise ValueError("evals must be an array")

    validated = []
    seen_ids = set()
    for idx, item in enumerate(evals, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"eval {idx} must be an object")
        eval_id = item.get("id", idx)
        if not isinstance(eval_id, int):
            raise ValueError(f"eval {idx} id must be an integer")
        if eval_id in seen_ids:
            raise ValueError(f"duplicate eval id: {eval_id}")
        seen_ids.add(eval_id)

        prompt = item.get("prompt", "")
        expected_output = item.get("expected_output", "")
        files = item.get("files", [])
        expectations = item.get("expectations", [])
        skill_type = item.get("skill_type")
        baseline_failure = item.get("baseline_failure")
        failure_form = item.get("failure_form")
        pressures = item.get("pressures", [])
        rationalizations = item.get("rationalizations", [])

        if not isinstance(prompt, str):
            raise ValueError(f"eval {eval_id} prompt must be a string")
        if not isinstance(expected_output, str):
            raise ValueError(f"eval {eval_id} expected_output must be a string")
        if not isinstance(files, list) or any(not isinstance(path, str) for path in files):
            raise ValueError(f"eval {eval_id} files must be an array of strings")
        if not isinstance(expectations, list) or any(not isinstance(text, str) for text in expectations):
            raise ValueError(f"eval {eval_id} expectations must be an array of strings")
        for field_name, value in (
            ("skill_type", skill_type),
            ("baseline_failure", baseline_failure),
            ("failure_form", failure_form),
        ):
            if value is not None and not isinstance(value, str):
                raise ValueError(f"eval {eval_id} {field_name} must be a string")
        for field_name, value in (("pressures", pressures), ("rationalizations", rationalizations)):
            if not isinstance(value, list) or any(not isinstance(text, str) for text in value):
                raise ValueError(f"eval {eval_id} {field_name} must be an array of strings")

        validated_item = {
            "id": eval_id,
            "prompt": prompt,
            "expected_output": expected_output,
            "files": files,
            "expectations": expectations,
        }
        optional_fields = {
            "skill_type": skill_type,
            "baseline_failure": baseline_failure,
            "failure_form": failure_form,
            "pressures": pressures,
            "rationalizations": rationalizations,
        }
        validated_item.update({key: value for key, value in optional_fields.items() if value is not None})
        validated.append(validated_item)

    return {"skill_name": skill_name.strip(), "evals": validated}


def generate_html(data: dict) -> str:
    template_path = Path(__file__).parent / "prompt_viewer.html"
    template = template_path.read_text()
    return template.replace("/*__EMBEDDED_DATA__*/", f"const EMBEDDED_DATA = {json.dumps(data)};")


def _kill_port(port: int) -> None:
    try:
        result = subprocess.run(
            ["lsof", "-ti", f":{port}"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        for pid_str in result.stdout.strip().split("\n"):
            if pid_str.strip():
                try:
                    os.kill(int(pid_str.strip()), signal.SIGTERM)
                except (ProcessLookupError, ValueError):
                    pass
        if result.stdout.strip():
            time.sleep(0.5)
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass


class PromptReviewHandler(BaseHTTPRequestHandler):
    def __init__(self, evals_path: Path, *args, **kwargs):
        self.evals_path = evals_path
        super().__init__(*args, **kwargs)

    def do_GET(self) -> None:
        if self.path == "/" or self.path == "/index.html":
            try:
                content = generate_html(load_evals(self.evals_path)).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "text/html; charset=utf-8")
                self.send_header("Content-Length", str(len(content)))
                self.end_headers()
                self.wfile.write(content)
            except Exception as exc:  # pragma: no cover - emergency path
                self.send_error(500, str(exc))
        elif self.path == "/api/evals":
            data = self.evals_path.read_bytes()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        else:
            self.send_error(404)

    def do_POST(self) -> None:
        if self.path != "/api/evals":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        try:
            payload = json.loads(body)
            validated = validate_evals(payload)
            self.evals_path.write_text(json.dumps(validated, indent=2) + "\n")
            response = b'{"ok":true}'
            self.send_response(200)
        except Exception as exc:
            response = json.dumps({"error": str(exc)}).encode("utf-8")
            self.send_response(400)

        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def log_message(self, format: str, *args: object) -> None:
        pass


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate and serve eval prompt approval UI")
    parser.add_argument("evals_path", type=Path, help="Path to evals/evals.json")
    parser.add_argument("--port", "-p", type=int, default=3118, help="Server port (default: 3118)")
    parser.add_argument(
        "--static",
        "-s",
        type=Path,
        default=None,
        help="Write standalone HTML to this path instead of starting a server",
    )
    args = parser.parse_args()

    evals_path = args.evals_path.resolve()
    if not evals_path.is_file():
        print(f"Error: {evals_path} is not a file", file=sys.stderr)
        sys.exit(1)

    data = load_evals(evals_path)
    validate_evals(data)

    if args.static:
        html = generate_html(data)
        args.static.parent.mkdir(parents=True, exist_ok=True)
        args.static.write_text(html)
        print(f"\n  Static prompt approval viewer written to: {args.static}\n")
        sys.exit(0)

    _kill_port(args.port)
    handler = partial(PromptReviewHandler, evals_path)
    try:
        server = HTTPServer(("127.0.0.1", args.port), handler)
        port = args.port
    except OSError:
        server = HTTPServer(("127.0.0.1", 0), handler)
        port = server.server_address[1]

    url = f"http://localhost:{port}"
    print("\n  Eval Prompt Approval Viewer")
    print("  ─────────────────────────────────")
    print(f"  URL:       {url}")
    print(f"  Evals:     {evals_path}")
    print("\n  Press Ctrl+C to stop.\n")

    webbrowser.open(url)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        server.server_close()


if __name__ == "__main__":
    main()
