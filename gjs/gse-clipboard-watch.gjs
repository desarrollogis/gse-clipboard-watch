
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
            gravity: Gdk.Gravity.STATIC,
            title: 'gse-clipboard-watch window',
        });
        this._get_maximized_info = false;
        this._move = false;
        this._resize = false;
        this._dock = false;
        this.connect('window-state-event', this._onWindowStateEvent.bind(this));
        this.connect('destroy', () => {
            Gtk.main_quit();
        });
        this._setGUI();
    }

    _onWindowStateEvent() {
        const [x, y] = this.get_position();
        const [width, height] = this.get_size();
        log(['_onWindowStateEvent', this._get_maximized_info, this._move, this._resize, this._dock, x, y, width, height]);

        if (this._get_maximized_info) {
            if (width > this._defaultWidth) {
                this._get_maximized_info = false;
                log(['_get_maximized_info', x, y, width, height]);
                [this._move, this._x, this._y, this._width, this._height] = [true, x, y, width, 48];
                this.unmaximize();
            }
            return;
        }
        if (this._move) {
            if (width == this._defaultWidth) {
                this._move = false;
                log(['_move', x, y, width, height]);
                this._resize = true;
                this.move(this._x, this._y);
            }
            return;
        }
        if (this._resize) {
            if ((x == this._x) && (y == this._y)) {
                this._resize = false;
                log(['_resize', x, y, width, height]);
                this._dock = true;
                this.resize(this._width, this._height);
            }
            return;
        }
        if (this._dock) {
            if ((width == this._width) && (height == this._height)) {
                this._dock = false;
                log(['_dock', x, y, width, height]);
                this.set_type_hint(Gdk.WindowTypeHint.DOCK);
                this._callBashScript(['bash', 'set_dock.sh']);
            }
            return;
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
        this._get_maximized_info = true;
        this.maximize();
    }
});

let window = new Window();

window.show_all();
window.dock();
Gtk.main();
