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
 *
 * Authored by: Corentin Noël <corentin@elementaryos.org>
 */

namespace Util {
    static bool has_scrolled = false;
    const uint interval = 500;

    public bool on_scroll_event (Gdk.EventScroll event) {
        double delta_x;
        double delta_y;
        event.get_scroll_deltas (out delta_x, out delta_y);

        double choice = delta_x;

        if (((int)delta_x).abs () < ((int)delta_y).abs ()) {
            choice = delta_y;
        }

        /* It's mouse scroll ! */
        if (choice == 1 || choice == -1) {
            DateTime.Widgets.CalendarModel.get_default ().change_month ((int)choice);

            return true;
        }

        if (has_scrolled == true) {
            return true;
        }

        if (choice > 0.3) {
            reset_timer.begin ();
            DateTime.Widgets.CalendarModel.get_default ().change_month (1);

            return true;
        }

        if (choice < -0.3) {
            reset_timer.begin ();
            DateTime.Widgets.CalendarModel.get_default ().change_month (-1);

            return true;
        }

        return false;
    }

    public GLib.DateTime get_start_of_month (owned GLib.DateTime? date = null) {
        if (date == null) {
            date = new GLib.DateTime.now_local ();
        }

        return new GLib.DateTime.local (date.get_year (), date.get_month (), 1, 0, 0, 0);
    }

    public GLib.DateTime strip_time (GLib.DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    /**
     * Converts the given ICal.Time to a DateTime.
     */
    public TimeZone timezone_from_ical (ICal.Time date) {
        int is_daylight;
        var interval = date.get_timezone ().get_utc_offset (date, out is_daylight);
        var hours = (interval / 3600).abs ();
        var minutes = (interval.abs () % 3600) / 60;
        var hour_string = "%s%02d:%02d".printf (hours >= 0 ? "+" : "-", hours, minutes);
        return new TimeZone (hour_string);
    }

    /**
     * Converts the given Time to a DateTime.
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public GLib.DateTime ical_to_date_time (ICal.Time date) {
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new GLib.DateTime (timezone_from_ical (date), year, month, day, hour, minute, second);
    }

    public ICal.Time date_time_to_ical (GLib.DateTime date) {
#if E_CAL_2_0
        int offset = (int)(date.get_utc_offset () / GLib.TimeSpan.SECOND);
        return new ICal.Time.from_timet_with_zone ((time_t) date.to_unix (), 0, ICal.Timezone.get_builtin_timezone_from_offset (offset, date.get_timezone_abbreviation ()));
#else
        return ICal.Time.from_timet_with_zone ((time_t) date.to_unix (), 0, ICal.Timezone.get_builtin_timezone_from_offset (date.get_utc_offset () / GLib.TimeSpan.SECOND, date.get_timezone_abbreviation ()));
#endif
    }

    public void get_local_datetimes_from_icalcomponent (ICal.Component comp, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        ICal.Time dt_start = comp.get_dtstart ();
        ICal.Time dt_end = comp.get_dtend ();

        start_date = Util.ical_to_date_time (dt_start);
        end_date = Util.ical_to_date_time (dt_end);
    }

    /**
     * Say if an event lasts all day.
     */
    public bool is_the_all_day (GLib.DateTime dtstart, GLib.DateTime dtend) {
        var UTC_start = dtstart.to_timezone (new TimeZone.utc ());
        var timespan = dtend.difference (dtstart);

        if (timespan % GLib.TimeSpan.DAY == 0 && UTC_start.get_hour () == 0) {
            return true;
        } else {
            return false;
        }
    }

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    public uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    public bool calcomponent_equal_func (ECal.Component a, ECal.Component b) {
        unowned ICal.Component comp_a = a.get_icalcomponent ();
        unowned ICal.Component comp_b = b.get_icalcomponent ();
        return comp_a.get_uid () == comp_b.get_uid ();
    }

    /* Returns true if 'a' and 'b' are the same E.Source */
    public bool source_equal_func (E.Source a, E.Source b) {
        return a.dup_uid () == b.dup_uid ();
    }

    public async void reset_timer () {
        has_scrolled = true;
        Timeout.add (interval, () => {
            has_scrolled = false;

            return false;
        });
    }
}
