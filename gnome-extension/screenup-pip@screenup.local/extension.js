import GLib from "gi://GLib";
import Meta from "gi://Meta";
import { Extension } from "resource:///org/gnome/shell/extensions/extension.js";

const WINDOW_TITLE = "ScreenUp PiP";
const APP_ID = "screenup-pip";
const REPIN_INTERVAL_MS = 500;
const DEFAULT_WIDTH = 480;
const DEFAULT_HEIGHT = 270;
const SCREEN_MARGIN = 24;

export default class ScreenUpPipExtension extends Extension {
    enable() {
        this._signals = [];
        this._pinnedWindows = new Set();

        this._signals.push([
            global.display,
            global.display.connect("window-created", (_display, window) => {
                this._watchWindow(window);
                this._pinWindow(window);
            }),
        ]);

        this._signals.push([
            global.display,
            global.display.connect("notify::focus-window", () => {
                this._reapplyPins();
            }),
        ]);

        for (const actor of global.get_window_actors()) {
            this._watchWindow(actor.meta_window);
        }

        this._reapplyPins();
        this._intervalId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, REPIN_INTERVAL_MS, () => {
            this._reapplyPins();
            return GLib.SOURCE_CONTINUE;
        });

        console.log("[ScreenUp PiP] Extensao ativada");
    }

    disable() {
        if (this._intervalId) {
            GLib.Source.remove(this._intervalId);
            this._intervalId = null;
        }

        for (const [object, signalId] of this._signals ?? []) {
            object.disconnect(signalId);
        }

        for (const [object, signalId] of this._windowSignals ?? []) {
            try {
                object.disconnect(signalId);
            } catch (_error) {
                // A janela pode ter sido destruida antes da extensao descarregar.
            }
        }

        this._signals = [];
        this._windowSignals = [];

        for (const window of this._pinnedWindows ?? []) {
            if (!window || window.is_above?.() !== true || window.is_destroyed?.() === true) {
                continue;
            }

            window.unmake_above();
        }

        this._pinnedWindows = new Set();
        console.log("[ScreenUp PiP] Extensao desativada");
    }

    _reapplyPins() {
        for (const actor of global.get_window_actors()) {
            this._watchWindow(actor.meta_window);
            this._pinWindow(actor.meta_window);
        }
    }

    _watchWindow(window) {
        if (!window || this._isWatched?.(window)) {
            return;
        }

        this._windowSignals ??= [];
        this._windowSignals.push([
            window,
            window.connect("notify::title", () => {
                this._pinWindow(window);
            }),
        ]);
    }

    _isWatched(window) {
        return (this._windowSignals ?? []).some(([watchedWindow]) => watchedWindow === window);
    }

    _pinWindow(window) {
        if (!window || window.get_window_type() !== Meta.WindowType.NORMAL) {
            return;
        }

        if (!this._matchesScreenUpWindow(window)) {
            return;
        }

        const wasPinned = this._pinnedWindows.has(window);
        this._pinnedWindows.add(window);
        this._forceAbove(window);
        this._moveToPictureInPictureCorner(window);

        if (!wasPinned) {
            console.log(`[ScreenUp PiP] Janela fixada: ${window.get_title?.() ?? "sem titulo"}`);
        }
    }

    _forceAbove(window) {
        if (window.is_minimized?.() === true) {
            window.unminimize();
        }

        window.make_above();
        window.stick();

        if (window.is_above?.() !== true) {
            window.make_above();
        }
    }

    _matchesScreenUpWindow(window) {
        const title = window.get_title?.() ?? "";
        const wmClass = window.get_wm_class?.() ?? "";
        const wmClassInstance = window.get_wm_class_instance?.() ?? "";
        const sandboxedAppId = window.get_sandboxed_app_id?.() ?? "";
        const description = window.get_description?.() ?? "";

        return [title, wmClass, wmClassInstance, sandboxedAppId, description].some((value) => {
            const normalizedValue = value.toLowerCase();
            return normalizedValue.includes(WINDOW_TITLE.toLowerCase()) ||
                normalizedValue.includes(APP_ID);
        });
    }

    _moveToPictureInPictureCorner(window) {
        const monitor = global.display.get_monitor_geometry(window.get_monitor());
        const frame = window.get_frame_rect();
        const width = Math.min(frame.width || DEFAULT_WIDTH, DEFAULT_WIDTH);
        const height = Math.min(frame.height || DEFAULT_HEIGHT, DEFAULT_HEIGHT);
        const x = monitor.x + monitor.width - width - SCREEN_MARGIN;
        const y = monitor.y + monitor.height - height - SCREEN_MARGIN;

        window.move_resize_frame(false, x, y, width, height);
    }
}
