#!/usr/bin/env python3
"""Run a bounded Godot validation against an isolated project copy."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import uuid


SCRIPT_ERROR = re.compile(r"^SCRIPT ERROR:", re.IGNORECASE | re.MULTILINE)
MAX_CONSOLE_OUTPUT = 64 * 1024


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run Godot headlessly with a deadline and an isolated user:// directory."
    )
    parser.add_argument("--godot", default="godot", help="Godot executable")
    parser.add_argument("--project", default=".", help="Project directory")
    parser.add_argument("--timeout", type=float, default=60.0, help="Deadline in seconds")
    parser.add_argument("--log", required=True, help="Combined stdout/stderr log file")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--import-project", action="store_true", help="Import and quit")
    mode.add_argument("--export-release", metavar="PRESET", help="Export a release build")
    parser.add_argument("--output", help="Export output path (required with --export-release)")
    parser.add_argument(
        "godot_args",
        nargs=argparse.REMAINDER,
        help="Project arguments, usually after -- (for example: -- --check)",
    )
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")
    if args.godot_args and args.godot_args[0] == "--":
        args.godot_args = args.godot_args[1:]
    if args.export_release and not args.output:
        parser.error("--output is required with --export-release")
    if args.output and not args.export_release:
        parser.error("--output requires --export-release")
    if not args.import_project and not args.export_release and not args.godot_args:
        parser.error("pass at least one Godot project argument after --")
    if (args.import_project or args.export_release) and args.godot_args:
        parser.error("project arguments after -- are only supported in normal run mode")
    return args


def isolated_project(source: Path, destination: Path, project_name: str | None) -> None:
    def ignored(path: str, names: list[str]) -> set[str]:
        result = set(names) & {".git", ".godot", "__pycache__", "artifacts", "build"}
        if Path(path).resolve() == source:
            result.update(set(names) & {"godot", "godot.zip", "templates.tpz", "tmpl"})
        return result

    shutil.copytree(source, destination, ignore=ignored)
    if project_name is None:
        return
    project_file = destination / "project.godot"
    contents = project_file.read_text(encoding="utf-8")
    replacement = f'config/name="{project_name}"'
    contents, substitutions = re.subn(
        r'^config/name="[^"]*"$', replacement, contents, count=1, flags=re.MULTILINE
    )
    if substitutions != 1:
        raise RuntimeError("project.godot has no single application config/name entry")
    project_file.write_text(contents, encoding="utf-8")


def signal_process(process: subprocess.Popen[str], sig: signal.Signals) -> None:
    if os.name == "posix":
        os.killpg(process.pid, sig)
    elif sig == signal.SIGTERM:
        process.terminate()
    else:
        process.kill()


def user_data_path(project_name: str, environment: dict[str, str]) -> Path | None:
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support" / "Godot" / "app_userdata" / project_name
    if os.name == "nt":
        app_data = environment.get("APPDATA")
        return Path(app_data) / "Godot" / "app_userdata" / project_name if app_data else None
    data_home = environment.get("XDG_DATA_HOME")
    base = Path(data_home) if data_home else Path.home() / ".local" / "share"
    return base / "godot" / "app_userdata" / project_name


def console_output(output: str) -> str:
    if len(output) <= MAX_CONSOLE_OUTPUT:
        return output
    omitted = len(output) - MAX_CONSOLE_OUTPUT
    return f"[... {omitted} characters omitted; full output is in the artifact ...]\n" + output[-MAX_CONSOLE_OUTPUT:]


def run_process(
    command: list[str], timeout: float, environment: dict[str, str]
) -> tuple[str, int, bool]:
    try:
        process = subprocess.Popen(
            command,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            env=environment,
            start_new_session=(os.name == "posix"),
        )
    except OSError as error:
        return f"ERROR: could not start Godot: {error}\n", 2, False

    try:
        output, _ = process.communicate(timeout=timeout)
        return output, process.returncode, False
    except subprocess.TimeoutExpired:
        signal_process(process, signal.SIGTERM)
        try:
            output, _ = process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            signal_process(process, signal.SIGKILL)
            output, _ = process.communicate()
        return output, 124, True


def main() -> int:
    args = parse_args()
    source = Path(args.project).resolve()
    godot = Path(args.godot).resolve() if os.sep in args.godot else Path(args.godot)
    log_path = Path(args.log).resolve()
    log_path.parent.mkdir(parents=True, exist_ok=True)

    if not (source / "project.godot").is_file():
        print(f"ERROR: project.godot not found in {source}", file=sys.stderr)
        return 2

    project_name = None if args.export_release else f"Symulator Ksiedza CI {uuid.uuid4().hex}"
    with tempfile.TemporaryDirectory(prefix="godot-validation-") as temporary:
        temporary_path = Path(temporary)
        project_copy = temporary_path / "project"
        isolated_project(source, project_copy, project_name)

        environment = os.environ.copy()
        # Godot honors XDG paths on Linux. The unique copied project name provides
        # the same user:// isolation on macOS and Windows without replacing HOME.
        if not args.export_release:
            environment["XDG_DATA_HOME"] = str(temporary_path / "xdg-data")
        environment["XDG_CONFIG_HOME"] = str(temporary_path / "xdg-config")
        environment["XDG_CACHE_HOME"] = str(temporary_path / "xdg-cache")
        base_command = [str(godot), "--headless", "--path", str(project_copy)]
        phases: list[tuple[str, list[str]]] = []
        if args.import_project:
            phases.append(("import", [*base_command, "--import"]))
        elif args.export_release:
            output_path = Path(args.output).resolve()
            output_path.parent.mkdir(parents=True, exist_ok=True)
            phases.append(("export", [*base_command, "--export-release", args.export_release, str(output_path)]))
        else:
            # A fresh checkout has no .godot cache. Import and validation must run
            # against the same copy so global classes are available to the game.
            phases.append(("import", [*base_command, "--import"]))
            phases.append(("run", [*base_command, "--", *args.godot_args]))

        chunks: list[str] = []
        return_code = 0
        timed_out = False
        script_error = False
        for phase_name, command in phases:
            output, phase_code, phase_timeout = run_process(command, args.timeout, environment)
            phase_script_error = SCRIPT_ERROR.search(output) is not None
            if phase_script_error and phase_code == 0:
                phase_code = 1
            chunks.append(
                f"=== {phase_name} ===\ncommand: {' '.join(command)}\n"
                f"timeout: {args.timeout:g}s\n{output}\n"
                f"phase_result: exit={phase_code} timed_out={str(phase_timeout).lower()} "
                f"script_error={str(phase_script_error).lower()}\n"
            )
            timed_out = timed_out or phase_timeout
            script_error = script_error or phase_script_error
            return_code = phase_code
            if phase_code != 0:
                break

        combined_output = "\n".join(chunks)
        footer = f"\nresult: exit={return_code} timed_out={str(timed_out).lower()} script_error={str(script_error).lower()}\n"
        log_path.write_text(combined_output + footer, encoding="utf-8")
        sys.stdout.write(console_output(combined_output))
        if timed_out:
            print(f"ERROR: a Godot process exceeded the {args.timeout:g}s deadline.", file=sys.stderr)
        if script_error:
            print("ERROR: Godot reported a script error.", file=sys.stderr)
        print(f"Validation log: {log_path}")
        isolated_user_data = user_data_path(project_name, environment) if project_name else None
        if isolated_user_data and isolated_user_data.is_dir():
            shutil.rmtree(isolated_user_data)
        return return_code


if __name__ == "__main__":
    raise SystemExit(main())
