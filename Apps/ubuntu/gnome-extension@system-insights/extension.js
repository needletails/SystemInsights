import Clutter from 'gi://Clutter';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import St from 'gi://St';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const CACHE_PATH = GLib.build_filenamev([
    GLib.get_user_data_dir(),
    'system-insights',
    'latest.snapshot',
]);
const CLI_PATH = GLib.build_filenamev([
    GLib.get_home_dir(),
    '.local',
    'bin',
    'system-insights',
]);

const Indicator = GObject.registerClass(
class Indicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'System Insights');

        this._label = new St.Label({
            text: 'Speed --',
            y_align: Clutter.ActorAlign.CENTER,
        });
        this.add_child(this._label);

        this._status = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._metrics = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._network = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._vpn = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._issue = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._activity = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._protocolNotice = new PopupMenu.PopupMenuItem('', {reactive: false});
        this._event = new PopupMenu.PopupMenuItem('', {reactive: false});
        for (const item of [
            this._status,
            this._metrics,
            this._network,
            this._vpn,
            this._issue,
            this._activity,
            this._protocolNotice,
            this._event,
        ]) {
            this.menu.addMenuItem(item);
        }

        this._reload();
        this._timerId = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 10, () => {
            this._reload();
            return GLib.SOURCE_CONTINUE;
        });

        try {
            this._fileMonitor = Gio.File.new_for_path(CACHE_PATH).monitor_file(
                Gio.FileMonitorFlags.NONE,
                null
            );
            this._monitorId = this._fileMonitor.connect('changed', () => this._reload());
        } catch (error) {
            this._fileMonitor = null;
        }
    }

    _readPanel() {
        if (!GLib.file_test(CLI_PATH, GLib.FileTest.IS_EXECUTABLE)) {
            throw new Error('missing-cli');
        }

        const [, stdout, , exitStatus] = GLib.spawn_command_line_sync(
            `'${CLI_PATH.replace(/'/g, `'\\''`)}' panel`
        );
        if (exitStatus !== 0 || !stdout?.length) {
            throw new Error('panel-failed');
        }
        return JSON.parse(new TextDecoder().decode(stdout));
    }

    _apply(panel) {
        this._label.text = panel.indicatorLabel ?? 'Speed --';
        this._setRatingStyle(panel.ratingStyle ?? 'unknown');
        this._status.label.text = panel.statusLine ?? '';
        this._metrics.label.text = panel.metricsLine ?? '';
        this._network.label.text = panel.networkLine ?? '';
        this._vpn.label.text = panel.vpnLine ?? '';
        this._issue.label.text = panel.issueLine ?? '';
        this._activity.label.text = panel.activityLine ?? '';
        this._protocolNotice.label.text = panel.protocolNoticeLine ?? '';
        this._event.label.text = panel.eventLine ?? '';
    }

    _reload() {
        try {
            this._apply(this._readPanel());
        } catch (error) {
            this._label.text = 'Speed --';
            this._setRatingStyle('unknown');
            const locked = String(error?.message ?? '').includes('locked');
            this._status.label.text = locked
                ? 'Cache locked — open System Insights and enter your password'
                : 'Unable to read encrypted snapshot';
            for (const item of [
                this._metrics,
                this._network,
                this._vpn,
                this._issue,
                this._activity,
                this._protocolNotice,
                this._event,
            ]) {
                item.label.text = '';
            }
        }
    }

    _setRatingStyle(rating) {
        for (const className of [
            'system-insights-good',
            'system-insights-warning',
            'system-insights-critical',
        ]) {
            this._label.remove_style_class_name(className);
        }
        if (rating === 'good' || rating === 'warning' || rating === 'critical') {
            this._label.add_style_class_name(`system-insights-${rating}`);
        }
    }

    destroy() {
        if (this._timerId) {
            GLib.source_remove(this._timerId);
            this._timerId = null;
        }
        if (this._fileMonitor) {
            if (this._monitorId) {
                this._fileMonitor.disconnect(this._monitorId);
            }
            this._fileMonitor.cancel();
            this._fileMonitor = null;
        }
        super.destroy();
    }
});

export default class SystemInsightsExtension extends Extension {
    enable() {
        this._indicator = new Indicator();
        this._indicator.connect('destroy', () => {
            this._indicator = null;
        });
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
