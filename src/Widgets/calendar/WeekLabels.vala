/*
 * Copyright 2011-2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authored by: Maxwell Barvian
 *              Corentin Noël <corentin@elementaryos.org>
 */

public class DateTime.Widgets.WeekLabels : Gtk.Revealer {
    private Gtk.Grid day_grid;
    private Gtk.Label[] labels;

    construct {
        vexpand = true;

        day_grid = new Gtk.Grid ();
        day_grid.attach (new Gtk.Separator (Gtk.Orientation.VERTICAL), 1, 0, 1, 6);
        day_grid.column_spacing = 9;
        day_grid.show ();

        add (day_grid);
    }

    public void update (GLib.DateTime date, int nr_of_weeks) {
        if (Services.SettingsManager.get_default ().show_weeks) {
            if (labels != null) {
                foreach (var label in labels) {
                    label.destroy ();
                }
            }

            var next = date;
            // Find the beginning of the week which is apparently always a monday
            int days_to_add = (8 - next.get_day_of_week ()) % 7;
            next = next.add_days (days_to_add);

            labels = new Gtk.Label[nr_of_weeks];
            for (int c = 0; c < nr_of_weeks; c++) {
                labels[c] = new Gtk.Label (next.get_week_of_year ().to_string ());
                labels[c].height_request = 30;
                labels[c].margin = 1;
                labels[c].valign = Gtk.Align.START;
                labels[c].width_chars = 2;
                labels[c].get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);
                labels[c].show ();

                day_grid.attach (labels[c], 0, c);

                next = next.add_weeks (1);
            }

            no_show_all = false;
            transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
            set_reveal_child (true);
        } else {
            transition_type = Gtk.RevealerTransitionType.SLIDE_LEFT;
            set_reveal_child (false);
            no_show_all = true;
            hide ();
        }
    }
}
