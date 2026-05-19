namespace SwayNotificationCenter.Widgets {
    public class Dnd : BaseWidget {
        public override string widget_name {
            get {
                return "dnd";
            }
        }

        Gtk.Label title_widget;
        Gtk.Switch dnd_button;

        // Default config values
        string title = "Do Not Disturb";
        string keybind = "d";

        public Dnd (string suffix) {
            base (suffix);

            Json.Object ?config = get_config (this);
            if (config != null) {
                // Get title
                string ?title = get_prop<string> (config, "text");
                if (title != null) {
                    this.title = title;
                }
                string ?k = get_prop<string> (config, "key");
                if (k != null) this.keybind = k;
            }

            // Title
            title_widget = new Gtk.Label (title);
            title_widget.set_hexpand (true);
            title_widget.set_halign (Gtk.Align.START);
            append (title_widget);

            // Dnd button
            dnd_button = new Gtk.Switch () {
                active = noti_daemon.dnd,
            };
            dnd_button.notify["active"].connect (switch_active_changed_cb);
            noti_daemon.on_dnd_toggle.connect ((dnd) => {
                dnd_button.notify["active"].disconnect (switch_active_changed_cb);
                dnd_button.set_active (dnd);
                dnd_button.notify["active"].connect (switch_active_changed_cb);
            });

            dnd_button.set_can_focus (false);
            dnd_button.valign = Gtk.Align.CENTER;
            // Backwards compatible towards older CSS stylesheets
            dnd_button.add_css_class ("control-center-dnd");
            append (dnd_button);
        }

        private void switch_active_changed_cb () {
            noti_daemon.dnd = dnd_button.active;
        }

        public override bool try_handle_key (string ?keyname) {
            if (!key_matches (keyname, keybind)) return false;
            try {
                swaync_daemon.toggle_dnd ();
            } catch (Error e) {
                critical ("Error: %s\n", e.message);
            }
            return true;
        }

        public override string ?get_help_entry () {
            if (keybind.length == 0) return null;
            return "%s\t%s".printf (keybind, title);
        }
    }
}
