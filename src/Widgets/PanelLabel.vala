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

public class DateTime.Widgets.PanelLabel : Gtk.Grid {
    private Gtk.Label date_label;
    private Gtk.Label time_label;
    private GLib.Settings indicator_settings;
    private GLib.Settings interface_settings;
    private unowned Services.TimeManager time_manager;

    private bool is_12h;
    private string date_format;
    private string time_format;

    construct {
        date_label = new Gtk.Label (null);
        date_label.margin_end = 12;

        var date_revealer = new Gtk.Revealer ();
        date_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
        date_revealer.add (date_label);

        time_label = new Gtk.Label (null);

        valign = Gtk.Align.CENTER;
        add (date_revealer);
        add (time_label);

        time_manager = Services.TimeManager.get_default ();
        time_manager.minute_changed.connect (update_labels);

        indicator_settings = new GLib.Settings ("io.elementary.desktop.wingpanel.datetime");
        indicator_settings.changed.connect ((key) => generate_settings (key));

        interface_settings = new GLib.Settings ("org.gnome.desktop.interface");
        interface_settings.bind ("clock-show-date", date_revealer, "reveal_child", SettingsBindFlags.DEFAULT);
        interface_settings.changed.connect ((key) => generate_settings (key));

        generate_settings ();
    }

    private void generate_settings (string? key = null) {
        if (key == null || key == "clock-format") {
            is_12h = interface_settings.get_string ("clock-format").contains ("12h");
        }

        if (key == null || key == "custom-date-format" || key == "clock-show-weekday") {
            bool clock_show_weekday = interface_settings.get_boolean ("clock-show-weekday");
            date_format = indicator_settings.get_string ("custom-date-format");
            if (date_format._strip () == "") {
                date_format = Granite.DateTime.get_default_date_format (clock_show_weekday, true, false);
            } else {
                // Ensure that the custom format is usable
                var result = (new GLib.DateTime.now_local ()).format (date_format);
                if (result == null) {
                    critical ("Unusable custom format, using standard one instead");
                    date_format = Granite.DateTime.get_default_date_format (clock_show_weekday, true, false);
                }
            }
        }

        if (key == null || key == "clock-format" || key == "clock-show-seconds") {
            bool clock_show_seconds = interface_settings.get_boolean ("clock-show-seconds");
            time_format = Granite.DateTime.get_default_time_format (is_12h, clock_show_seconds);
        }

        update_labels ();
    }

    private void update_labels () {
        date_label.label = time_manager.format (date_format);
        time_label.label = time_manager.format (time_format);
    }
        
}
