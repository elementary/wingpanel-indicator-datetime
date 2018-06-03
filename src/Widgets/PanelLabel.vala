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

    private GLib.Settings clock_settings;
    public string clock_format { get; set; }
    public bool show_date { get; set; }
    public bool show_seconds { get; set; }
    public bool show_weekday { get; set; }

    public PanelLabel () {
        clock_settings = Services.DesktopSettings.get ();
        clock_settings.bind ("clock-format", this, "clock-format", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-date", this, "show-date", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-seconds", this, "show-seconds", SettingsBindFlags.DEFAULT);
        clock_settings.bind ("clock-show-weekday", this, "show-weekday", SettingsBindFlags.DEFAULT);

        // Update Labels on Settings Change
        notify.connect (() => {
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
            string date_format = Granite.DateTime.get_default_date_format (show_weekday, true, false);
            date_label.label = Services.TimeManager.get_default ().format (date_format);
        } else {
            date_label.label = "";
        }

        string time_format = Granite.DateTime.get_default_time_format (clock_format == "12h", show_seconds);
        time_label.label = Services.TimeManager.get_default ().format (time_format);
    }
        
}
