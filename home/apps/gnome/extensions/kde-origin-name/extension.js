// Permanent version of the Looking Glass snippet:
//   const d = Main.notificationDaemon._fdoNotificationDaemon;
//   d.GetCapabilities = () => [...new Set([...orig.call(d), 'x-kde-origin-name'])];
//
// The org.freedesktop.Notifications proxy process forwards GetCapabilities to
// the shell's FdoNotificationDaemon over D-Bus, so overriding the method on
// that instance is enough. Chrome queries capabilities once at startup, so it
// must be restarted after this extension is (en|dis)abled.

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const CAPABILITY = 'x-kde-origin-name';

export default class KdeOriginNameExtension extends Extension {
    enable() {
        this._daemon = Main.notificationDaemon._fdoNotificationDaemon;
        this._original = this._daemon.GetCapabilities;
        const original = this._original;
        this._daemon.GetCapabilities = function (...args) {
            return [...new Set([...original.apply(this, args), CAPABILITY])];
        };
    }

    disable() {
        if (this._daemon && this._original)
            this._daemon.GetCapabilities = this._original;
        this._daemon = null;
        this._original = null;
    }
}
