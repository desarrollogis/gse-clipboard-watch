
imports.gi.versions.Gtk = '3.0';

const { Gtk, GObject, Gdk, Gio } = imports.gi;

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
            title: 'gse-clipboard-watch window',
        });
        this._set_position = false;
        this._dock = false;
        this.connect('window-state-event', this._onWindowStateEvent.bind(this));
        this.connect('destroy', () => {
            Gtk.main_quit();
        });
        this._setGUI();
    }

    _onWindowStateEvent(widget, event) {
        if (this._set_position) {
            const state = this.get_window().get_state();
            const mask = Gdk.WindowState.MAXIMIZED;

            if ((state & mask) != mask) {
                return;
            }

            const [width, height] = this.get_size();

            if (width == this._defaultWidth) {
                return;
            }
            this._set_position = false;

            const [x, y] = this.get_position();

            this.unmaximize();
            this.set_type_hint(Gdk.WindowTypeHint.DOCK);
            this.move(x, y);
            this._dock = true;
            this.resize(width, 48);
        } else {
            if (this._dock) {
                const [width, height] = this.get_size();

                if (height == 48) {
                    this._callBashScript(['bash', 'set_dock.sh']);
                    this._dock = true;
                }
            }
        }
    }

    _callBashScript(script) {
        let proc = Gio.Subprocess.new(script, Gio.SubprocessFlags.STDOUT_PIPE);
        let cancellable = new Gio.Cancellable();
        let result = proc.communicate_utf8(null, cancellable)[1];

        return result;
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

    dock() {
        [this._defaultWidth, this._defaultHeight] = this.get_size();
        this._set_position = true;
        this.maximize();
    }
});

let window = new Window();

window.show_all();
window.dock();
Gtk.main();
