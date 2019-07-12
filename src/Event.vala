/*
 * Copyright 2011-2019 elementary, Inc. (https://elementary.io)
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

public class DateTime.Event : GLib.Object {
    public GLib.DateTime date { get; construct; }
    public unowned iCal.Component component { get; construct; }
    public Util.DateRange range { get; construct; }

    public GLib.DateTime start_time;
    public GLib.DateTime end_time;
    public bool day_event = false;

    private bool alarm = false;

    public Event (GLib.DateTime date, Util.DateRange range, iCal.Component component) {
        Object (
            component: component,
            date: date,
            range: range
        );
    }

    construct {
        start_time = Util.ical_to_date_time (component.get_dtstart ());
        end_time = Util.ical_to_date_time (component.get_dtend ());

        if (end_time == null) {
            alarm = true;
        } else if (Util.is_the_all_day (start_time, end_time)) {
            day_event = true;
        }
    }

    public string get_event_label () {
        return component.get_summary ();
    }

    public string get_event_times () {
        if (day_event) {
            return "";
        }
        return "%s - %s".printf (start_time.format (get_time_format ()), end_time.format (get_time_format ()));
    }

    public string get_icon () {
        if (alarm) {
            return "alarm-symbolic";
        }
        return "office-calendar-symbolic";
    }

    private string get_time_format () {
        /* If AM/PM doesn't exist, use 24h. */
        if (Posix.nl_langinfo (Posix.NLItem.AM_STR) == null || Posix.nl_langinfo (Posix.NLItem.AM_STR) == "") {
            return Granite.DateTime.get_default_time_format (false);
        }

        /* If AM/PM exists, assume it is the default time format and check for format override. */
        var setting = new GLib.Settings ("org.gnome.desktop.interface");
        var clockformat = setting.get_user_value ("clock-format");

        if (clockformat == null) {
            return Granite.DateTime.get_default_time_format (true);
        }

        if (clockformat.get_string ().contains ("12h")) {
            return Granite.DateTime.get_default_time_format (true);
        } else {
            return Granite.DateTime.get_default_time_format (false);
        }
    }
}
