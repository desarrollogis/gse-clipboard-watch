
imports.gi.versions.Gtk = '3.0';

const { Gtk, GObject, GdkPixbuf, Gdk, Gio } = imports.gi;

Gtk.init(null);

var Window = GObject.registerClass(class Window extends Gtk.Window {
    _init() {
        super._init({
            defaultWidth: 200,
            defaultHeight: 64,
            gravity: Gdk.Gravity.STATIC,
            title: "gse-clipboard-watch",
        });
        this.connect('destroy', () => {
            Gtk.main_quit();
        });
        this.set_decorated(false);
        this.setPosition();

        let grid = new Gtk.Grid({
            margin: 10,
            "baseline-row": Gtk.BaselinePosition.CENTER,
            "column-homogeneous": true,
            "column-spacing": 10,
            "row-homogeneous": true,
            "row-spacing": 10,
        });

        this.add(grid);
        this._buttons = [];
        for (let i = 0, m = 5; i < m; ++i) {
            const button = new Gtk.Button({ label: "" });

            grid.attach(button, i, 0, 1, 1);
            this._buttons.push(button);
        }

        const atom = Gdk.Atom.intern('CLIPBOARD', false);
        const clipboard = Gtk.Clipboard.get(atom);

        clipboard.connect('owner-change', this._ownerChange.bind(this));
    }

    setPosition() {
        let screen = this.get_screen();
        let current = screen.get_monitor_at_window(screen.get_active_window());
        let monitors = [];

        for (let i = 0, m = screen.get_display().get_n_monitors(); i < m; ++i) {
            monitors.push(screen.get_monitor_geometry(i));
        }

        let x = monitors[current].x;
        let y = monitors[current].y;
        let width = monitors[current].width;

        this.move(x, y);
        this.resize(width, 64);
    }

    fixPosition() {
        const stdout = this._callBashScript(['bash', 'get_absolute_position.sh']).trim();

        if (stdout == "") {
            return;
        }

        const [x, y, width, height] = stdout.split(' ');

        this.set_type_hint(Gdk.WindowTypeHint.DOCK);
        this.move(x, y);
        this.resize(width, height);
        this._callBashScript(['bash', 'set_dock.sh']);
    }

    _callBashScript(script) {
        let proc = Gio.Subprocess.new(script, Gio.SubprocessFlags.STDOUT_PIPE);
        let cancellable = new Gio.Cancellable();
        let result = proc.communicate_utf8(null, cancellable)[1];

        return result;
    }

    _ownerChange(clipboard) {
        const isAvailable = clipboard.wait_is_text_available();

        if (!isAvailable) {
            return;
        }

        const text = clipboard.wait_for_text().split()[0];

        for (let i = this._buttons.length - 1; i > 0; --i) {
            this._buttons[i].set_label(this._buttons[i - 1].get_label());
        }
        this._buttons[0].set_label(text);
    }
});

let window = new Window();

window.show_all();
window.fixPosition();
Gtk.main();
