#!/usr/bin/env gjs

imports.gi.versions.Gtk = '3.0';

const { Gtk, Gdk, Gio, GLib, GObject } = imports.gi;

Gtk.init(null);

var ClipboardButton = GObject.registerClass(class ClipboardButton extends Gtk.Button {
    _init() {
        super._init({});
        this.setText('');
        this.connect('clicked', this._onClick.bind(this));
    }

    setText(text) {
        this._text = text;

        const row = text.split('\n')[0].trim();
        const rowLength = row.length;
        const label = (rowLength < 16) ? row : row.substring(0, 8) + '...' + row.substring(rowLength - 8);

        this.set_label(label);
        this.set_tooltip_text(text);
    }

    _onClick() {
        if (this._text == '') {
            return;
        }

        const atom = Gdk.Atom.intern('CLIPBOARD', false);
        const clipboard = Gtk.Clipboard.get(atom);

        clipboard.set_text(this._text, -1);
    }

    getText() {
        return this._text;
    }
});

var Window = GObject.registerClass(class Window extends Gtk.Window {
    _init() {
        super._init({
            decorated: false,
            defaultWidth: 200,
            defaultHeight: 200,
            gravity: Gdk.Gravity.STATIC,
            title: 'gse-clipboard-watch window',
        });
        this._width = 0;
        this._signal = false;
        this.connect('notify::type-hint', this._onNotifyTypeHint.bind(this));
        this._signal = this.connect('window-state-event', this._onWindowStateEvent.bind(this));
        this.connect('notify::is-maximized', this._onNotifyIsMaximized.bind(this));
        this._setGUI();
    }

    _onNotifyTypeHint() {
        this.move(this._x, this._y);
        this.resize(this._width, this._height);
        GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
            this._onWindowStateEvent();
            return this._signal ? GLib.SOURCE_CONTINUE : GLib.SOURCE_REMOVE;
        });
    }

    _onWindowStateEvent() {
        const [x, y] = this.get_position();
        const [width, height] = this.get_size();

        if (this.is_maximized) {
            if (width > this._width) {
                this._x = x;
                this._y = y;
                this._width = width;
                this._height = 48;
            }
            return;
        }
        if ((x == this._x) && (y == this._y) && (width == this._width) && (height == this._height)) {
            this._callBashScript(['bash', 'set_dock.sh']);
            this.disconnect(this._signal);
            this._signal = false;
        }
    }

    _callBashScript(script) {
        let proc = Gio.Subprocess.new(script, Gio.SubprocessFlags.STDOUT_PIPE);
        let cancellable = new Gio.Cancellable();
        let result = proc.communicate_utf8(null, cancellable)[1];

        return result;
    }

    _onNotifyIsMaximized() {
        if (this.is_maximized) {
            this.unmaximize();
        } else {
            this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        }
    }

    _setGUI() {
        this._grid = new Gtk.Grid({
            margin: 4,
            'baseline-row': Gtk.BaselinePosition.CENTER,
            'column-homogeneous': true,
            'column-spacing': 4,
            'row-homogeneous': true,
            'row-spacing': 4,
        });
        this.add(this._grid);
        this._buttons = [];
        for (let i = 0, m = 5; i < m; ++i) {
            const button = new ClipboardButton();

            this._grid.attach(button, i, 0, 1, 1);
            this._buttons.push(button);
        }

        const atom = Gdk.Atom.intern('CLIPBOARD', false);
        const clipboard = Gtk.Clipboard.get(atom);

        clipboard.connect('owner-change', this._ownerChange.bind(this));
    }

    _ownerChange(clipboard) {
        const isAvailable = clipboard.wait_is_text_available();

        if (!isAvailable) {
            return;
        }

        const text = clipboard.wait_for_text().trim();
        let texts = [];

        texts.push(text);
        for (let i = 0, m = this._buttons.length; i < m; ++i) {
            texts.push(this._buttons[i].getText());
        }
        texts = [...new Set(texts)];
        while (texts.length < this._buttons.length) {
            texts.push('');
        }
        for (let i = 0, m = this._buttons.length; i < m; ++i) {
            this._buttons[i].setText(texts[i]);
        }
    }
});

let window = new Window();

window.show_all();
window.maximize();
Gtk.main();
