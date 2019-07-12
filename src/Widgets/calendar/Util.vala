/*
 * Copyright (c) 2011-2016 elementary LLC. (https://elementary.io)
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
     * Converts the given TimeType to a DateTime.
     */
    public TimeZone timezone_from_ical (iCal.TimeType date) {
        var interval = date.zone.get_utc_offset (date, date.is_daylight);
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
     * Converts the given TimeType to a DateTime.
     * XXX : Track next versions of evolution in order to convert iCal.Timezone to GLib.TimeZone with a dedicated function…
     */
    public GLib.DateTime ical_to_date_time (iCal.TimeType date) {
        return new GLib.DateTime (timezone_from_ical (date), date.year, date.month,
                                  date.day, date.hour, date.minute, date.second);
    }

    public void get_local_datetimes_from_icalcomponent (iCal.Component comp, out GLib.DateTime start_date, out GLib.DateTime end_date) {
        iCal.TimeType dt_start = comp.get_dtstart ();
        iCal.TimeType dt_end = comp.get_dtend ();

        start_date = Util.ical_to_date_time (dt_start);
        end_date = Util.ical_to_date_time (dt_end);
    }

    public Gee.Collection<DateRange> event_date_ranges (iCal.Component comp, Util.DateRange view_range) {
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
        unowned iCal.Property property = comp.get_first_property (iCal.PropertyKind.RRULE);

        if (property != null) {
            var rrule = property.get_rrule ();

            switch (rrule.freq) {
                case (iCal.RecurrenceTypeFrequency.WEEKLY) :
                    generate_week_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.MONTHLY) :
                    generate_month_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                case (iCal.RecurrenceTypeFrequency.YEARLY) :
                    generate_year_reccurence (dateranges, view_range, rrule, start, end);
                    break;
                default :
                    generate_day_reccurence (dateranges, view_range, rrule, start, end);
                    break;
            }
        }

        /* EXDATEs elements are exceptions dates that should not appear. */
        property = comp.get_first_property (iCal.PropertyKind.EXDATE);

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

            property = comp.get_next_property (iCal.PropertyKind.EXDATE);
        }

        return dateranges;
    }

    private void generate_day_reccurence (Gee.LinkedList<DateRange> dateranges, Util.DateRange view_range,
                                          iCal.RecurrenceType rrule, GLib.DateTime start, GLib.DateTime end) {
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
                                           iCal.RecurrenceType rrule, GLib.DateTime start, GLib.DateTime end) {
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
                                            iCal.RecurrenceType rrule, GLib.DateTime start, GLib.DateTime end) {
        /* Computes month recurrences by day (for example: third friday of the month). */
        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
            if (rrule.by_day[k] < iCal.Size.BY_DAY) {
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
        if (rrule.by_month_day[0] < iCal.Size.BY_MONTHDAY) {
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
                                           iCal.RecurrenceType rrule, GLib.DateTime start_, GLib.DateTime end_) {
        GLib.DateTime start = start_;
        GLib.DateTime end = end_;

        for (int k = 0; k <= iCal.Size.BY_DAY; k++) {
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

        switch (iCal.RecurrenceType.day_day_of_week (day)) {
            case iCal.RecurrenceTypeWeekday.SUNDAY:
                day_to_add = 7 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.MONDAY:
                day_to_add = 1 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.TUESDAY:
                day_to_add = 2 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.WEDNESDAY:
                day_to_add = 3 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.THURSDAY:
                day_to_add = 4 - date.get_day_of_week ();
                break;
            case iCal.RecurrenceTypeWeekday.FRIDAY:
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

        switch (iCal.RecurrenceType.day_position (day)) {
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

    /*
     * Gee Utility Functions
     */

    /* Computes hash value for E.Source */
    public uint source_hash_func (E.Source key) {
        return key.dup_uid (). hash ();
    }

    /* Returns true if 'a' and 'b' are the same E.CalComponent */
    public bool calcomponent_equal_func (E.CalComponent a, E.CalComponent b) {
        unowned iCal.Component comp_a = a.get_icalcomponent ();
        unowned iCal.Component comp_b = b.get_icalcomponent ();
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
