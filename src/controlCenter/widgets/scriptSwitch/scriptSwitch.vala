namespace SwayNotificationCenter.Widgets {
    public class ScriptSwitch : BaseWidget {
        public override string widget_name {
            get {
                return "script-switch";
            }
        }

        private Gtk.Label title_widget;
        private Gtk.Switch toggle;
        private ulong toggle_handler_id;

        private string title = "Toggle";
        private string command = "";
        private string update_command = "";
        private string keybind = "";

        public ScriptSwitch (string suffix) {
            base (suffix);

            Json.Object ?config = get_config (this);
            if (config != null) {
                string ?text = get_prop<string> (config, "text");
                if (text != null) this.title = text;

                string ?cmd = get_prop<string> (config, "command");
                if (cmd != null) this.command = cmd;

                string ?ucmd = get_prop<string> (config, "update-command");
                if (ucmd != null) this.update_command = ucmd;

                string ?k = get_prop<string> (config, "key");
                if (k != null) this.keybind = k;
            }

            title_widget = new Gtk.Label (title);
            title_widget.set_hexpand (true);
            title_widget.set_halign (Gtk.Align.START);
            append (title_widget);

            toggle = new Gtk.Switch ();
            toggle.set_can_focus (false);
            toggle.valign = Gtk.Align.CENTER;
            toggle_handler_id = toggle.notify["active"].connect (on_toggle);
            append (toggle);
        }

        private void on_toggle () {
            if (command.length == 0) return;
            run_command.begin (command);
        }

        private async void run_command (string cmd) {
            string msg = "";
            string[] env_additions = { "SWAYNC_TOGGLE_STATE=" + toggle.active.to_string () };
            yield Functions.execute_command (cmd, env_additions, out msg);
        }

        public override void on_cc_visibility_change (bool value) {
            if (value && update_command.length > 0) {
                refresh_state.begin ();
            }
        }

        public override bool try_handle_key (string ?keyname) {
            if (!key_matches (keyname, keybind)) return false;
            toggle.set_active (!toggle.active);
            return true;
        }

        public override string ?get_help_entry () {
            if (keybind.length == 0) return null;
            return "%s\t%s".printf (keybind, title);
        }

        private async void refresh_state () {
            string msg = "";
            string[] env_additions = { "SWAYNC_TOGGLE_STATE=" + toggle.active.to_string () };
            yield Functions.execute_command (update_command, env_additions, out msg);

            try {
                Regex regex = new Regex ("\\s+$");
                string res = regex.replace (msg, msg.length, 0, "");
                GLib.SignalHandler.block (toggle, toggle_handler_id);
                toggle.set_active (res.up () == "TRUE");
                GLib.SignalHandler.unblock (toggle, toggle_handler_id);
            } catch (RegexError e) {
                stderr.printf ("RegexError: %s\n", e.message);
            }
        }
    }
}
