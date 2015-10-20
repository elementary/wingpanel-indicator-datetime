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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class DateTime.Widgets.Calendar : Gtk.Calendar {
    private const string CALENDAR_EXEC = "/usr/bin/maya-calendar";

    public signal void date_doubleclicked ();

    public Calendar () {
        this.margin_start = 10;
        this.margin_end = 10;

        this.day_selected_double_click.connect (() => {
            show_date_in_maya ();
            date_doubleclicked ();
        });
    }

    public void show_today () {
        var current_time = Services.TimeManager.get_default ().get_current_time ();

        if (current_time == null) {
            return;
        }

        this.select_month (current_time.get_month () - 1, current_time.get_year ());
        this.select_day (current_time.get_day_of_month ());
    }

    /* TODO: As far as maya supports it use the Dbus Activation feature to run the calendar-app. */
    private void show_date_in_maya () {
        uint selected_year, selected_month, selected_day;
        this.get_date (out selected_year, out selected_month, out selected_day);

        /* Month-correction */
        selected_month += 1;

        var parameter_string = @" --show-day $selected_day/$selected_month/$selected_year";
        var command = CALENDAR_EXEC + parameter_string;

        var cmd = new Granite.Services.SimpleCommand ("/usr/bin", command);
        cmd.run ();
    }
}