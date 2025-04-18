/*
 * Copyright (c) 2011-2015 elementary LLC. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 */

public class DateTime.Widgets.PanelLabel : Gtk.Box {
    private Gtk.Label date_label;
    private Gtk.Label time_label;
    private Services.TimeManager time_manager;

    public string clock_format { get; set; }
    public bool clock_show_seconds { get; set; }
    public bool clock_show_weekday { get; set; }

    construct {
        date_label = new Gtk.Label (null) {
            margin_end = 12
        };

        var date_revealer = new Gtk.Revealer () {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT,
            child = date_label
        };

        time_label = new Gtk.Label (null) {
            use_markup = true
        };

        valign = Gtk.Align.CENTER;
        append (date_revealer);
        append (time_label);

        var clock_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
        clock_settings.bind ("clock-format", this, "clock-format", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-seconds", this, "clock-show-seconds", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-date", date_revealer, "reveal_child", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-weekday", this, "clock-show-weekday", SettingsBindFlags.DEFAULT);

        notify.connect (() => {
            update_labels ();
        });

        time_manager = Services.TimeManager.get_default ();
        time_manager.minute_changed.connect (update_labels);
        time_manager.notify["is-12h"].connect (update_labels);

        var gesture_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_MIDDLE
        };
        gesture_click.pressed.connect (on_pressed);
        add_controller (gesture_click);
    }

    private void update_labels () {
        string date_format;
        if (clock_format == "ISO8601") {
            date_format = "%F";
        } else {
            date_format = Granite.DateTime.get_default_date_format (clock_show_weekday, true, false);
        }

        date_label.label = time_manager.format (date_format);

        string time_format = Granite.DateTime.get_default_time_format (time_manager.is_12h, clock_show_seconds);
        time_label.label = GLib.Markup.printf_escaped ("<span font_features='tnum'>%s</span>", time_manager.format (time_format));
    }

    private void on_pressed () {
        var command = "io.elementary.calendar --show-day %s".printf (new GLib.DateTime.now_local ().format ("%F"));
        try {
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE);
            appinfo.launch_uris (null, null);
        } catch (GLib.Error e) {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Unable To Launch Calendar"),
                _("The program \"io.elementary.calendar\" may not be installed"),
                "dialog-error"
            );
            dialog.show_error_details (e.message);
            dialog.response.connect ((_dialog, response) => _dialog.destroy ());
            dialog.present ();
        }
    }
}
