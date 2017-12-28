/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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

    private GLib.Settings clockSettings;
    public string date_format { get; set; }
    public bool show_date { get; set; }
    public bool show_seconds { get; set; }

    public PanelLabel () {
        clockSettings = new GLib.Settings ("org.gnome.desktop.interface");
        clockSettings.bind("clock-format", this, "date-format", SettingsBindFlags.DEFAULT);
        clockSettings.bind("clock-show-date", this, "show-date", SettingsBindFlags.DEFAULT);
        clockSettings.bind("clock-show-seconds", this, "show-seconds", SettingsBindFlags.DEFAULT);

        // Update Labels on Settings Change
        this.notify.connect ((sender, property) => {
            update_labels ();
        });

        Services.TimeManager.get_default ().time_changed.connect (update_labels);
    }

    construct {
        orientation = Gtk.Orientation.HORIZONTAL;
        column_spacing = 12;
        valign = Gtk.Align.CENTER;

        date_label = new Gtk.Label (null);
        time_label = new Gtk.Label (null);

        this.add (date_label);
        this.add (time_label);
    }

    private void update_labels () {
        if (show_date) {
            /// TRANSLATORS: Date format in the panel following http://valadoc.org/#!api=glib-2.0/GLib.DateTime.format */
            date_label.set_label (Services.TimeManager.get_default ().format (_("%a, %b %e")));
        } else {
            date_label.set_label ("");
        }

        string format = "";

        if ((date_format == "24h") && show_seconds) {
            format = "%H:%M:%S";
        } else if ((date_format == "24h") && !show_seconds) {
            format = "%H:%M";
        } else if ((date_format != "24h") && show_seconds) {
            format = "%l:%M:%S %p";
        } else if ((date_format != "24h") && !show_seconds) {
            format = "%l:%M %p";
        } else {
            format = "";
        }

        time_label.set_label (Services.TimeManager.get_default ().format (format));
    }
        
}
