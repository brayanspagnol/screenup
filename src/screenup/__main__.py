from __future__ import annotations

import shutil
import sys

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
from gi.repository import Gdk, Gio, GLib, Gtk

from .mpv_player import MpvPlayer
from .youtube import parse_youtube_url


APP_CSS = """
window {
  background: #0f111a;
}

.app-shell {
  background: linear-gradient(145deg, #141827, #0d0f16);
}

.hero-card {
  border-radius: 22px;
  padding: 22px;
  background: rgba(255, 255, 255, 0.08);
  box-shadow: 0 18px 44px rgba(0, 0, 0, 0.34);
}

.app-title {
  color: #ffffff;
  font-size: 26px;
  font-weight: 800;
}

.app-subtitle {
  color: rgba(245, 247, 255, 0.72);
  font-size: 13px;
}

.url-entry {
  min-height: 48px;
  border-radius: 14px;
  padding: 0 14px;
  color: #ffffff;
  font-size: 15px;
  background: rgba(255, 255, 255, 0.08);
}

.loading-row {
  min-height: 28px;
}

.status {
  color: rgba(245, 247, 255, 0.78);
  font-size: 13px;
}

.error {
  color: #ffd8de;
  background: rgba(255, 72, 96, 0.22);
}
"""


def apply_app_style() -> None:
    provider = Gtk.CssProvider()
    provider.load_from_data(APP_CSS.encode("utf-8"))
    display = Gdk.Display.get_default()

    if display is not None:
        Gtk.StyleContext.add_provider_for_display(
            display,
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )


class ScreenUpWindow(Gtk.ApplicationWindow):
    def __init__(self, app: Gtk.Application) -> None:
        super().__init__(application=app, title="ScreenUp")
        self.player = MpvPlayer()
        self.pending_load_source: int | None = None
        self.loading_source: int | None = None

        self.set_icon_name("screenup")
        self.set_default_size(520, 210)
        self.set_resizable(False)

        root = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        root.add_css_class("app-shell")
        root.set_margin_top(18)
        root.set_margin_bottom(18)
        root.set_margin_start(18)
        root.set_margin_end(18)
        self.set_child(root)

        card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        card.add_css_class("hero-card")
        root.append(card)

        title = Gtk.Label(label="ScreenUp")
        title.add_css_class("app-title")
        title.set_halign(Gtk.Align.START)
        card.append(title)

        subtitle = Gtk.Label(label="YouTube em Picture-in-Picture, sempre acima.")
        subtitle.add_css_class("app-subtitle")
        subtitle.set_halign(Gtk.Align.START)
        card.append(subtitle)

        self.url_entry = Gtk.Entry()
        self.url_entry.set_placeholder_text("Cole a URL do YouTube")
        self.url_entry.set_hexpand(True)
        self.url_entry.add_css_class("url-entry")
        self.url_entry.connect("changed", self._on_url_changed)
        self.url_entry.connect("activate", self._load_url_from_entry)

        url_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        url_row.append(self.url_entry)
        card.append(url_row)

        loading_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        loading_row.add_css_class("loading-row")
        self.spinner = Gtk.Spinner()
        self.spinner.set_visible(False)
        loading_row.append(self.spinner)

        self.status_label = Gtk.Label(label="Cole uma URL do YouTube para comecar.")
        self.status_label.add_css_class("status")
        self.status_label.set_halign(Gtk.Align.START)
        self.status_label.set_wrap(True)
        loading_row.append(self.status_label)
        card.append(loading_row)

        self.connect("close-request", self._on_close_request)

    def _on_url_changed(self, *_args: object) -> None:
        if self.pending_load_source is not None:
            GLib.Source.remove(self.pending_load_source)

        self.pending_load_source = GLib.timeout_add(450, self._load_url_from_entry)

    def _load_url_from_entry(self, *_args: object) -> bool:
        self.pending_load_source = None
        raw_url = self.url_entry.get_text().strip()

        if not raw_url:
            return GLib.SOURCE_REMOVE

        if not self._check_dependencies():
            return GLib.SOURCE_REMOVE

        try:
            parsed_url = parse_youtube_url(raw_url)
        except ValueError:
            return GLib.SOURCE_REMOVE

        try:
            self.player.play(parsed_url.original_url)
        except ValueError as error:
            self._set_status(str(error), is_error=True)
            return GLib.SOURCE_REMOVE
        except FileNotFoundError:
            self._set_status("Nao encontrei o mpv. Instale com: sudo dnf install mpv yt-dlp", is_error=True)
            return GLib.SOURCE_REMOVE

        self._set_loading(True, "Abrindo player...")

        if self.loading_source is not None:
            GLib.Source.remove(self.loading_source)

        self.loading_source = GLib.timeout_add(200, self._poll_player_ready)
        return GLib.SOURCE_REMOVE

    def _poll_player_ready(self) -> bool:
        if self.player.is_ready():
            self.loading_source = None
            self._set_loading(False, "Player aberto.")
            return GLib.SOURCE_REMOVE

        if not self.player.is_running():
            self.loading_source = None
            self._set_loading(False, "O mpv fechou antes de abrir o player.", is_error=True)
            return GLib.SOURCE_REMOVE

        return GLib.SOURCE_CONTINUE

    def _on_close_request(self, *_args: object) -> bool:
        if self.pending_load_source is not None:
            GLib.Source.remove(self.pending_load_source)
            self.pending_load_source = None

        if self.loading_source is not None:
            GLib.Source.remove(self.loading_source)
            self.loading_source = None

        self.player.stop()
        return False

    def _check_dependencies(self) -> bool:
        missing = [binary for binary in ("mpv", "yt-dlp") if shutil.which(binary) is None]

        if missing:
            self._set_status(
                f"Dependencias ausentes: {', '.join(missing)}. Instale com: sudo dnf install mpv yt-dlp",
                is_error=True,
            )
            return False

        return True

    def _set_status(self, message: str, *, is_error: bool = False) -> None:
        self.status_label.set_text(message)
        self.status_label.remove_css_class("error")

        if is_error:
            self.status_label.add_css_class("error")

    def _set_loading(self, is_loading: bool, message: str, *, is_error: bool = False) -> None:
        self.spinner.set_visible(is_loading)

        if is_loading:
            self.spinner.start()
        else:
            self.spinner.stop()

        self._set_status(message, is_error=is_error)


class ScreenUpApp(Gtk.Application):
    def __init__(self) -> None:
        super().__init__(application_id="local.screenup.Pip", flags=Gio.ApplicationFlags.DEFAULT_FLAGS)

    def do_activate(self) -> None:
        apply_app_style()
        window = self.props.active_window

        if window is None:
            window = ScreenUpWindow(self)

        window.present()


def main() -> int:
    app = ScreenUpApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    raise SystemExit(main())
