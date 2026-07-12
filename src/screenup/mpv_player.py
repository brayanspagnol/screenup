from __future__ import annotations

import json
import os
import socket
import subprocess
import tempfile
from pathlib import Path


APP_ID = "screenup-pip"
WINDOW_TITLE = "ScreenUp PiP"


class MpvPlayer:
    def __init__(self) -> None:
        runtime_dir = Path(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir()))
        self.socket_path = runtime_dir / f"{APP_ID}.sock"
        self.controls_script_path = Path(__file__).parent / "mpv" / "pip_controls.lua"
        self.process: subprocess.Popen[str] | None = None
        self.supported_options = self._load_supported_options()

    def play(self, url: str) -> None:
        self.stop()
        self._remove_stale_socket()

        command = [
            "mpv",
            "--no-terminal",
            "--force-window=yes",
            "--idle=no",
            "--osc=no",
            "--ytdl=yes",
            "--ytdl-format=bestvideo[height<=720]+bestaudio/best[height<=720]/best",
            "--keep-open=no",
            "--geometry=480x270-24-24",
            "--autofit=480x270",
            "--cache=yes",
            "--demuxer-max-bytes=128MiB",
            "--demuxer-max-back-bytes=128MiB",
            "--demuxer-readahead-secs=20",
            "--audio-buffer=1.5",
            "--hr-seek=no",
            "--border",
            "--ontop",
            f"--title={WINDOW_TITLE}",
            f"--force-media-title={WINDOW_TITLE}",
            f"--input-ipc-server={self.socket_path}",
            f"--script={self.controls_script_path}",
            "--script-opts=ytdl_hook-ytdl_path=yt-dlp",
            url,
        ]

        if "ontop-level" in self.supported_options:
            command.append("--ontop-level=system")

        if "x11-name" in self.supported_options:
            command.append(f"--x11-name={APP_ID}")

        if "wayland-app-id" in self.supported_options:
            command.append(f"--wayland-app-id={APP_ID}")

        self.process = subprocess.Popen(command, text=True)

    def stop(self) -> None:
        if not self.process:
            self._remove_stale_socket()
            return

        if self.process.poll() is None:
            try:
                self.command(["quit"])
                self.process.wait(timeout=2)
            except Exception:
                self.process.terminate()
                try:
                    self.process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    self.process.kill()
                    self.process.wait(timeout=1)

        self.process = None
        self._remove_stale_socket()

    def toggle_pause(self) -> None:
        self.command(["cycle", "pause"])

    def set_volume(self, volume: int) -> None:
        clamped_volume = max(0, min(volume, 100))
        self.command(["set_property", "volume", clamped_volume])

    def resize(self, width: int, height: int) -> None:
        self.command(["set_property", "window-scale", 1])
        self.command(["set_property", "geometry", f"{width}x{height}-24-24"])

    def command(self, command: list[object]) -> None:
        payload = json.dumps({"command": command}).encode("utf-8") + b"\n"

        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
            client.settimeout(0.5)
            client.connect(str(self.socket_path))
            client.sendall(payload)

    def is_running(self) -> bool:
        return self.process is not None and self.process.poll() is None

    def is_ready(self) -> bool:
        return self.is_running() and self.socket_path.exists()

    def _remove_stale_socket(self) -> None:
        try:
            self.socket_path.unlink()
        except FileNotFoundError:
            pass

    def _load_supported_options(self) -> set[str]:
        try:
            result = subprocess.run(
                ["mpv", "--list-options"],
                check=True,
                capture_output=True,
                text=True,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            return set()

        options: set[str] = set()

        for line in result.stdout.splitlines():
            option = line.strip().split(" ", 1)[0].removeprefix("--")
            if option:
                options.add(option)

        return options
