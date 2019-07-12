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
    public E.Source source {get; construct;}
    public E.SourceCalendar? cal {get; construct;}

    public GLib.DateTime start_time;
    public GLib.DateTime end_time;
    public bool day_event = false;

    private bool alarm = false;

    public Event (GLib.DateTime date, Util.DateRange range, iCal.Component component, E.Source source) {
        Object (
            component: component,
            date: date,
            source: source,
            range: range
        );
    }

    construct {
        Util.get_local_datetimes_from_icalcomponent (component, out start_time, out end_time);

        if (end_time == null) {
            alarm = true;
        } else if (Util.is_the_all_day (start_time, end_time)) {
            day_event = true;
        }

        cal = (E.SourceCalendar?)source.get_extension (E.SOURCE_EXTENSION_CALENDAR);
    }

    public string get_event_label () {
        return component.get_summary ();
    }

    public string get_event_times () {
        if (day_event) {
            return "";
        }
        return "%s - %s".printf (start_time.format (Util.TimeFormat ()), end_time.format (Util.TimeFormat ()));
    }

    public string get_icon () {
        if (alarm) {
            return "alarm-symbolic";
        }
        return "office-calendar-symbolic";
    }
}
