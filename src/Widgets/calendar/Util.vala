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

    public int compare_events (ECal.Component comp1, ECal.Component comp2) {
        var res = comp1.get_icalcomponent ().get_dtstart ().compare (comp2.get_icalcomponent ().get_dtstart ());
        if (res != 0)
            return res;

        // If they have the same date, sort them alphabetically
        return compare_event_alphabetically (comp1, comp2);
    }

    public int compare_event_alphabetically (ECal.Component comp1, ECal.Component comp2) {
        return comp1.get_summary ().get_value ().collate (comp2.get_summary ().get_value ());
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
        var interval = date.get_timezone ().get_utc_offset (null, out is_daylight);
        bool is_positive = interval >= 0;
        interval = interval.abs ();
        var hours = (interval / 3600);
        var minutes = (interval % 3600)/60;
        var hour_string = "%s%02d:%02d".printf (is_positive ? "+" : "-", hours, minutes);

        return new TimeZone (hour_string);
    }

    /**
     * Converts the given ICal.Time to a DateTime.
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public GLib.DateTime ical_to_date_time (ICal.Time date) {
        return new GLib.DateTime (timezone_from_ical (date), date.year, date.month,
            date.day, date.hour, date.minute, date.second);
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

    public GLib.DateTime get_date_from_ical_day (GLib.DateTime date, short day) {
        int day_to_add = 0;

        switch (ICal.Recurrence.day_day_of_week (day)) {
            case ICal.RecurrenceWeekday.SUNDAY_WEEKDAY:
                day_to_add = 7 - date.get_day_of_week ();
                break;
            case ICal.RecurrenceWeekday.MONDAY_WEEKDAY:
                day_to_add = 1 - date.get_day_of_week ();
                break;
            case ICal.RecurrenceWeekday.TUESDAY_WEEKDAY:
                day_to_add = 2 - date.get_day_of_week ();
                break;
            case ICal.RecurrenceWeekday.WEDNESDAY_WEEKDAY:
                day_to_add = 3 - date.get_day_of_week ();
                break;
            case ICal.RecurrenceWeekday.THURSDAY_WEEKDAY:
                day_to_add = 4 - date.get_day_of_week ();
                break;
            case ICal.RecurrenceWeekday.FRIDAY_WEEKDAY:
                day_to_add = 5 - date.get_day_of_week ();
                break;
            default:
                day_to_add = 6 - date.get_day_of_week ();
                break;
        }

        if (date.add_days (day_to_add).get_month () < date.get_month ()) {
            day_to_add = day_to_add + 7;
        }

        if (date.add_days (day_to_add).get_month () > date.get_month ()) {
            day_to_add = day_to_add - 7;
        }

        switch (ICal.Recurrence.day_position (day)) {
            case 1:
                int n = (int)GLib.Math.trunc ((date.get_day_of_month () + day_to_add) / 7);

                return date.add_days (day_to_add - n * 7);
            case 2:
                int n = (int)GLib.Math.trunc ((date.get_day_of_month () + day_to_add - 7) / 7);

                return date.add_days (day_to_add - n * 7);
            case 3:
                int n = (int)GLib.Math.trunc ((date.get_day_of_month () + day_to_add - 14) / 7);

                return date.add_days (day_to_add - n * 7);
            case 4:
                int n = (int)GLib.Math.trunc ((date.get_day_of_month () + day_to_add - 21) / 7);

                return date.add_days (day_to_add - n * 7);
            default:
                int n = (int)GLib.Math.trunc ((date.get_day_of_month () + day_to_add - 28) / 7);

                return date.add_days (day_to_add - n * 7);
        }
    }

    private Gee.HashMap<string, Gtk.CssProvider>? providers;
    public void set_event_calendar_color (E.SourceCalendar cal, Gtk.Widget widget) {
        if (providers == null) {
            providers = new Gee.HashMap<string, Gtk.CssProvider> ();
        }

        var color = cal.dup_color ();
        if (!providers.has_key (color)) {
            string style = """
                @define-color colorAccent %s;
            """.printf (color);

            try {
                var style_provider = new Gtk.CssProvider ();
                style_provider.load_from_data (style, style.length);

                providers[color] = style_provider;
            } catch (Error e) {
                critical ("Unable to set calendar color: %s", e.message);
            }
        }

        unowned Gtk.StyleContext style_context = widget.get_style_context ();
        style_context.add_provider (providers[color], Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    public uint source_hash_func (E.Source key) {
        return key.get_uid ().hash ();
    }

    /* Returns true if 'a' and 'b' are the same ECal.Component */
    public bool calcomponent_equal_func (ECal.Component a, ECal.Component b) {
        return a.get_id ().equal (b.get_id ());
    }

    /* Returns true if 'a' and 'b' are the same E.Source */
    public bool source_equal_func (E.Source a, E.Source b) {
        return a.get_uid () == b.get_uid ();
    }

    public int calcomponent_compare_func (ECal.Component? a, ECal.Component? b) {
        if (a == null && b != null) {
            return 1;
        } else if (b == null && a != null) {
            return -1;
        } else if (b == null && a == null) {
            return 0;
        }

        var a_id = a.get_id ();
        var b_id = b.get_id ();
        int res = GLib.strcmp (a_id.get_uid (), b_id.get_uid ());
        if (res == 0) {
            return GLib.strcmp (a_id.get_rid (), b_id.get_rid ());
        }

        return res;
    }

    public bool calcomp_is_on_day (ECal.Component comp, GLib.DateTime day) {
        ECal.ComponentDateTime start_dt;
        ECal.ComponentDateTime end_dt;

        comp.get_dtstart (out start_dt);
        comp.get_dtend (out end_dt);

        var stripped_time = new GLib.DateTime.local (day.get_year (), day.get_month (), day.get_day_of_month (), 0, 0, 0);

        var selected_date_unix = stripped_time.to_unix ();
        var selected_date_unix_next = stripped_time.add_days (1).to_unix ();
        time_t start_unix;
        time_t end_unix;

        /* We want to be relative to the local timezone */
        start_unix = (*start_dt.value).as_timet_with_zone (ECal.Util.get_system_timezone ());
        end_unix = (*end_dt.value).as_timet_with_zone (ECal.Util.get_system_timezone ());

        /* If the selected date is inside the event */
        if (start_unix < selected_date_unix && selected_date_unix_next < end_unix) {
            return true;
        }

        /* If the event start before the selected date but finished in the selected date */
        if (start_unix < selected_date_unix && selected_date_unix < end_unix) {
            return true;
        }

        /* If the event start after the selected date but finished after the selected date */
        if (start_unix < selected_date_unix_next && selected_date_unix_next < end_unix) {
            return true;
        }

        /* If the event is inside the selected date */
        if (start_unix < selected_date_unix_next && selected_date_unix < end_unix) {
            return true;
        }

        return false;
    }

    public async void reset_timer () {
        has_scrolled = true;
        Timeout.add (interval, () => {
            has_scrolled = false;

            return false;
        });
    }
}
