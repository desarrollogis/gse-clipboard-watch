
imports.gi.versions.Gtk = '3.0';

const { Gtk, GObject, GdkPixbuf, Gdk, Gio } = imports.gi;

Gtk.init(null);

var Window = GObject.registerClass(class Window extends Gtk.Window {
    _init() {
        super._init({
            defaultWidth: 200,
            defaultHeight: 100,
            gravity: Gdk.Gravity.STATIC,
            title: "Clipboard Watch",
        });
        this.connect('destroy', () => {
            Gtk.main_quit();
        });
        this.set_name('gse-clipboard-watch');
        //this.set_type_hint(Gdk.WindowTypeHint.DOCK);
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

        let entry_text = new Gtk.Entry();

        grid.attach(entry_text, 0, 0, 1, 1);

        let buttonCopyText = new Gtk.Button({ label: "Copiar texto" });

        grid.attach(buttonCopyText, 1, 0, 1, 1);

        let buttonPasteText = new Gtk.Button({ label: "Pegar texto" });

        grid.attach(buttonPasteText, 2, 0, 1, 1);

        let file = '/usr/share/icons/gnome/128x128/apps/org.gnome.ChromeGnomeShell.png';
        let pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_size(file, 32, 32);
        let entry_image = Gtk.Image.new_from_pixbuf(pixbuf);

        grid.attach(entry_image, 0, 1, 1, 1);

        let buttonCopyImage = new Gtk.Button({ label: "Copiar imagen" });

        grid.attach(buttonCopyImage, 1, 1, 1, 1);

        let buttonPasteImage = new Gtk.Button({ label: "Pegar imagen" });

        grid.attach(buttonPasteImage, 2, 1, 1, 1);
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
        this.resize(width, 100);
    }

    fixPosition() {
        const {Gio} = imports.gi;

        let proc = Gio.Subprocess.new(['bash', 'get_absolute_position.sh'], Gio.SubprocessFlags.STDOUT_PIPE);

        proc.communicate_utf8_async(null, null, (proc, result) => {
            try {
                let [, stdout] = proc.communicate_utf8_finish(result);

                if (proc.get_successful()) {
                    let [x, y, width, height] = stdout.trim().split(' ');

                    this.set_type_hint(Gdk.WindowTypeHint.DOCK);
                    this.move(x, y);
                    this.resize(width, height);
                }
            } catch(e) {
                logError(e);
            }
        });
    }
});

let window = new Window();

window.show_all();
window.fixPosition();
Gtk.main();
