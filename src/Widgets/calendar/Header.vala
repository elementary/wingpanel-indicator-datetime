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

/**
 * Represents the header at the top of the calendar grid.
 */
public class DateTime.Widgets.Header : Gtk.EventBox {
    private Gtk.Label[] labels;

    construct {
        var header_grid = new Gtk.Grid ();
        header_grid.column_homogeneous = true;
        header_grid.margin_bottom = 4;

        labels = new Gtk.Label[7];
        for (int c = 0; c < 7; c++) {
            labels[c] = new Gtk.Label (null);
            labels[c].get_style_context ().add_class (Granite.STYLE_CLASS_H4_LABEL);

            header_grid.add (labels[c]);
        }

        add (header_grid);
    }

    public void update_columns (int week_starts_on) {
        var date = Util.strip_time (new GLib.DateTime.now_local ());
        date = date.add_days (week_starts_on - date.get_day_of_week ());
        foreach (var label in labels) {
            label.label = date.format ("%a");
            date = date.add_days (1);
        }
    }
}
