/*
 * Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace DateTimeIndicator {
    public class Models.CalendarModel : Object {
        /* The data_range is the range of dates for which this model is storing
         * data.
         *
         * There is no way to set the ranges publicly. They can only be modified by
         * changing one of the following properties: month_start, num_weeks, and
         * week_starts_on.
         */
        public Util.DateRange data_range { get; private set; }

        /* The first day of the month */
        public GLib.DateTime month_start { get; set; }

        /* The number of weeks to show in this model */
        public int num_weeks { get; private set; default = 6; }

        /* The start of week, ie. Monday=1 or Sunday=7 */
        public GLib.DateWeekday week_starts_on { get; set; }

        private static CalendarModel? calendar_model = null;

        public static CalendarModel get_default () {
            lock (calendar_model) {
                if (calendar_model == null) {
                    calendar_model = new CalendarModel ();
                }
            }

            return calendar_model;
        }

        construct {
            int week_start = Posix.NLTime.FIRST_WEEKDAY.to_string ().data[0];
            if (week_start >= 1 && week_start <= 7) {
                week_starts_on = (GLib.DateWeekday) (week_start - 1);
            }

            month_start = Util.get_start_of_month ();
            compute_ranges ();
        }

        public void change_month (int m_relative, int y_relative = 0) {
            if (y_relative == 0) {
                month_start = month_start.add_months (m_relative);
            } else {
                if (m_relative == 0) {
                    month_start = month_start.add_years (y_relative);
                } else {
                    GLib.DateTime tmp_date = month_start.add_months (m_relative);
                    month_start = tmp_date.add_years (y_relative);
                }
            }
        }

        /* --- Helper Methods ---// */

        public void compute_ranges () {
            var month_end = month_start.add_full (0, 1, -1);

            int dow = month_start.get_day_of_week ();
            int wso = (int)week_starts_on;
            int offset = 0;

            if (wso < dow) {
                offset = dow - wso;
            } else if (wso > dow) {
                offset = 7 + dow - wso;
            }

            var data_range_first = month_start.add_days (-offset);

            dow = month_end.get_day_of_week ();
            wso = (int)(week_starts_on + 6);

            /* WSO must be between 1 and 7 */
            if (wso > 7) {
                wso = wso - 7;
            }

            offset = 0;

            if (wso < dow) {
                offset = 7 + wso - dow;
            } else if (wso > dow) {
                offset = wso - dow;
            }

            var data_range_last = month_end.add_days (offset);

            data_range = new Util.DateRange (data_range_first, data_range_last);
            num_weeks = data_range.to_list ().size / 7;

            debug (@"Date ranges: ($data_range_first <= $month_start < $month_end <= $data_range_last)");
        }
    }
}
