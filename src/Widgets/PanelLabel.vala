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

    public string clock_format { get; set; }

    construct {
        var clock_settings = new GLib.Settings ("org.gnome.desktop.interface");
        clock_settings.bind ("clock-format", this, "clock-format", SettingsBindFlags.DEFAULT);

        update_labels ();

        notify["clock-format"].connect (() => {
            update_labels ();
        });

        Services.TimeManager.get_default ().minute_changed.connect (update_labels);

        date_label = new Gtk.Label (null);
        time_label = new Gtk.Label (null);

        column_spacing = 12;
        valign = Gtk.Align.CENTER;
        add (date_label);
        add (time_label);
    }

    private void update_labels () {
        /// TRANSLATORS: Date format in the panel following https://valadoc.org/glib-2.0/GLib.DateTime.format.html */
        date_label.set_label (Services.TimeManager.get_default ().format (_("%a, %b %e")));

        if (clock_format == "24h") {
            time_label.set_label (Services.TimeManager.get_default ().format ("%H:%M"));
        } else {
            /// TRANSLATORS: Time format in the panel following https://valadoc.org/glib-2.0/GLib.DateTime.format.html */
            time_label.set_label (Services.TimeManager.get_default ().format (_("%l:%M %p")));
        }
    }
        
}
