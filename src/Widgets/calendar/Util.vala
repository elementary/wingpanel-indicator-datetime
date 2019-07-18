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
    public void get_style_calendar_color (E.SourceCalendar cal, Gtk.CssProvider provider) {
        var color = cal.dup_color ();
        string style = """
                        @define-color colorAccent %s;
                       """.printf(color);
        try {
            provider.load_from_data (style, style.length);
        } catch (Error e) {
            warning ("Could not create CSS Provider: %s\nStylesheet:\n%s", e.message, style);
        }
    }

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
        var hours = (interval / 3600);
        string hour_string = "-";

        if (hours >= 0) {
            hour_string = "+";
        }

        hours = hours.abs ();

        if (hours > 9) {
            hour_string = "%s%d".printf (hour_string, hours);
        } else {
            hour_string = "%s0%d".printf (hour_string, hours);
        }

        var minutes = (interval.abs () % 3600) / 60;

        if (minutes > 9) {
            hour_string = "%s:%d".printf (hour_string, minutes);
        } else {
            hour_string = "%s:0%d".printf (hour_string, minutes);
        }

        return new TimeZone (hour_string);
    }

    /**
     * Converts the given ICal.Time to a DateTime.
     * XXX : Track next versions of evolution in order to convert ICal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public GLib.DateTime ical_to_date_time (ICal.Time date) {
        int year, month, day, hour, minute, second;
        date.get_date (out year, out month, out day);
        date.get_time (out hour, out minute, out second);
        return new GLib.DateTime (timezone_from_ical (date), year, month, day, hour, minute, second);
    }

    public Gee.Collection<DateRange> event_date_ranges (ICal.Component comp, Util.DateRange view_range) {
        var dateranges = new Gee.LinkedList<DateRange> ();

        var start = ical_to_date_time (comp.get_dtstart ());
        var end = ical_to_date_time (comp.get_dtend ());

        if (end == null) {
            end = start;
        }

        /* All days events are stored in UTC time and should only being shown at one day. */
        bool allday = is_the_all_day (start, end);

        if (allday) {
            end = end.add_days (-1);
            var interval = (new GLib.DateTime.now_local ()).get_utc_offset ();
            start = start.add (-interval);
            end = end.add (-interval);
        }

        start = strip_time (start.to_timezone (new TimeZone.local ()));
        end = strip_time (end.to_timezone (new TimeZone.local ()));
        dateranges.add (new Util.DateRange (start, end));

        /* Search for recursive events. */
        unowned ICal.Property property = comp.get_first_property (ICal.PropertyKind.RRULE_PROPERTY);

        if (property != null) {
            var rrule = property.get_rrule ();

            switch (rrule.freq) {
                case (ICal.RecurrenceFrequency.WEEKLY_RECURRENCE) :
                    generate_week_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (ICal.RecurrenceFrequency.MONTHLY_RECURRENCE) :
                    generate_month_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (ICal.RecurrenceFrequency.YEARLY_RECURRENCE) :
                    generate_year_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                default :
                    generate_day_reccurence (dateranges, view_range, rrule, start, end);
                    break;
            }
        }

        /* EXDATE_PROPERTYs elements are exceptions dates that should not appear. */
        property = comp.get_first_property (ICal.PropertyKind.EXDATE_PROPERTY);

        while (property != null) {
            var exdate = property.get_exdate ();
            var date = ical_to_date_time (exdate);
            dateranges.@foreach ((daterange) => {
                var first = daterange.first_dt;
                var last = daterange.last_dt;

                if (first.get_year () <= date.get_year () && last.get_year () >= date.get_year ()) {
                    if (first.get_day_of_year () <= date.get_day_of_year () && last.get_day_of_year () >= date.get_day_of_year ()) {
                        dateranges.remove (daterange);

                        return false;
                    }
                }

                return true;
            });

            property = comp.get_next_property (ICal.PropertyKind.EXDATE_PROPERTY);
        }

        return dateranges;
    }

    private void generate_day_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                          ICal.Recurrence rrule, GLib.DateTime start, GLib.DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            for (int i = 1; i <= (int)(rrule.until.day / rrule.interval); i++) {
                int n = i * rrule.interval;

                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n))) {
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                }
            }
        } else if (rrule.count > 0) {
            for (int i = 1; i <= rrule.count; i++) {
                int n = i * rrule.interval;

                if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n))) {
                    dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                }
            }
        } else {
            int i = 1;
            int n = i * rrule.interval;

            while (view_range.last_dt.compare (start.add_days (n)) > 0) {
                dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                i++;
                n = i * rrule.interval;
            }
        }
    }

    private void generate_year_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           ICal.Recurrence rrule, GLib.DateTime start, GLib.DateTime end) {
        if (rrule.until.is_null_time () == 0) {
            /*for (int i = 0; i <= rrule.until.year; i++) {
             *   int n = i*rrule.interval;
             *   if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n)))
             *       dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
             *  }*/
        } else if (rrule.count > 0) {
            for (int i = 1; i <= rrule.count; i++) {
                int n = i * rrule.interval;

                if (view_range.contains (start.add_years (n)) || view_range.contains (end.add_years (n))) {
                    dateranges.add (new Util.DateRange (start.add_years (n), end.add_years (n)));
                }
            }
        } else {
            int i = 1;
            int n = i * rrule.interval;
            bool is_null_time = rrule.until.is_null_time () == 1;
            var temp_start = start.add_years (n);

            while (view_range.last_dt.compare (temp_start) > 0) {
                if (is_null_time == false) {
                    if (temp_start.get_year () > rrule.until.year) {
                        break;
                    } else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month) {
                        break;
                    } else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day) {
                        break;
                    }
                }

                dateranges.add (new Util.DateRange (temp_start, end.add_years (n)));
                i++;
                n = i * rrule.interval;
                temp_start = start.add_years (n);
            }
        }
    }

    private void generate_month_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                            ICal.Recurrence rrule, GLib.DateTime start, GLib.DateTime end) {
        /* Computes month recurrences by day (for example: third friday of the month). */
        for (int k = 0; k <= ICal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] < ICal.Size.BY_DAY) {
                if (rrule.count > 0) {
                    for (int i = 1; i <= rrule.count; i++) {
                        int n = i * rrule.interval;
                        var start_ical_day = get_date_from_ical_day (start.add_months (n), rrule.by_day[k]);
                        int interval = start_ical_day.get_day_of_month () - start.get_day_of_month ();
                        dateranges.add (new Util.DateRange (start_ical_day, end.add_months (n).add_days (interval)));
                    }
                } else {
                    int i = 1;
                    int n = i * rrule.interval;
                    bool is_null_time = rrule.until.is_null_time () == 1;
                    var start_ical_day = get_date_from_ical_day (start.add_months (n), rrule.by_day[k]);
                    int week_of_month = (int)GLib.Math.ceil ((double)start.get_day_of_month () / 7);

                    while (view_range.last_dt.compare (start_ical_day) > 0) {
                        if (is_null_time == false) {
                            if (start_ical_day.get_year () > rrule.until.year) {
                                break;
                            } else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () > rrule.until.month) {
                                break;
                            } else if (start_ical_day.get_year () == rrule.until.year && start_ical_day.get_month () == rrule.until.month && start_ical_day.get_day_of_month () > rrule.until.day) {
                                break;
                            }
                        }

                        /* Set it at the right weekday */
                        int interval = start_ical_day.get_day_of_month () - start.get_day_of_month ();
                        var start_daterange_date = start_ical_day;
                        var end_daterange_date = end.add_months (n).add_days (interval);
                        var new_week_of_month = (int)GLib.Math.ceil ((double)start_daterange_date.get_day_of_month () / 7);

                        /* Set it at the right week */
                        if (week_of_month != new_week_of_month) {
                            start_daterange_date = start_daterange_date.add_weeks (week_of_month - new_week_of_month);
                            end_daterange_date = end_daterange_date.add_weeks (week_of_month - new_week_of_month);
                        }

                        dateranges.add (new Util.DateRange (start_daterange_date, end_daterange_date));
                        i++;
                        n = i * rrule.interval;
                        start_ical_day = get_date_from_ical_day (start.add_months (n), rrule.by_day[k]);
                    }
                }
            } else {
                break;
            }
        }

        /* Computes month recurrences by month day (for example: 4th of the month). */
        if (rrule.by_month_day[0] < ICal.Size.BY_MONTHDAY) {
            if (rrule.count > 0) {
                for (int i = 1; i <= rrule.count; i++) {
                    int n = i * rrule.interval;
                    dateranges.add (new Util.DateRange (start.add_months (n), end.add_months (n)));
                }
            } else {
                int i = 1;
                int n = i * rrule.interval;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_months (n);

                while (view_range.last_dt.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year) {
                            break;
                        } else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () > rrule.until.month) {
                            break;
                        } else if (temp_start.get_year () == rrule.until.year && temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day) {
                            break;
                        }
                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_months (n)));
                    i++;
                    n = i * rrule.interval;
                    temp_start = start.add_months (n);
                }
            }
        }
    }

    private void generate_week_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                           ICal.Recurrence rrule, GLib.DateTime start_, GLib.DateTime end_) {
        GLib.DateTime start = start_;
        GLib.DateTime end = end_;

        for (int k = 0; k <= ICal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] > 7) {
                break;
            }

            int day_to_add = 0;

            switch (rrule.by_day[k]) {
                case 1:
                    day_to_add = 7 - start.get_day_of_week ();
                    break;
                case 2:
                    day_to_add = 1 - start.get_day_of_week ();
                    break;
                case 3:
                    day_to_add = 2 - start.get_day_of_week ();
                    break;
                case 4:
                    day_to_add = 3 - start.get_day_of_week ();
                    break;
                case 5:
                    day_to_add = 4 - start.get_day_of_week ();
                    break;
                case 6:
                    day_to_add = 5 - start.get_day_of_week ();
                    break;
                default:
                    day_to_add = 6 - start.get_day_of_week ();
                    break;
            }

            if (start.add_days (day_to_add).get_month () < start.get_month ()) {
                day_to_add = day_to_add + 7;
            }

            start = start.add_days (day_to_add);
            end = end.add_days (day_to_add);

            if (rrule.count > 0) {
                for (int i = 1; i <= rrule.count; i++) {
                    int n = i * rrule.interval * 7;

                    if (view_range.contains (start.add_days (n)) || view_range.contains (end.add_days (n))) {
                        dateranges.add (new Util.DateRange (start.add_days (n), end.add_days (n)));
                    }
                }
            } else {
                int i = 1;
                int n = i * rrule.interval * 7;
                bool is_null_time = rrule.until.is_null_time () == 1;
                var temp_start = start.add_days (n);

                while (view_range.last_dt.compare (temp_start) > 0) {
                    if (is_null_time == false) {
                        if (temp_start.get_year () > rrule.until.year) {
                            break;
                        } else if (temp_start.get_year () == rrule.until.year) {
                            if (temp_start.get_month () > rrule.until.month) {
                                break;
                            } else if (temp_start.get_month () == rrule.until.month && temp_start.get_day_of_month () > rrule.until.day) {
                                break;
                            }
                        }
                    }

                    dateranges.add (new Util.DateRange (temp_start, end.add_days (n)));
                    i++;
                    n = i * rrule.interval * 7;
                    temp_start = start.add_days (n);
                }
            }
        }
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
