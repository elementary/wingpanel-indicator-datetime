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
            Calendar.Store.get_event_store ().change_month ((int)choice);
            Calendar.Store.get_task_store ().change_month ((int)choice);

            return true;
        }

        if (has_scrolled == true) {
            return true;
        }

        if (choice > 0.3) {
            reset_timer.begin ();
            Calendar.Store.get_event_store ().change_month (1);
            Calendar.Store.get_task_store ().change_month (1);

            return true;
        }

        if (choice < -0.3) {
            reset_timer.begin ();
            Calendar.Store.get_event_store ().change_month (-1);
            Calendar.Store.get_task_store ().change_month (-1);

            return true;
        }

        return false;
    }

    private Gee.HashMap<string, Gtk.CssProvider>? providers;
    public void set_source_selectable_color (E.SourceSelectable source_selectable, Gtk.Widget widget) {
        if (providers == null) {
            providers = new Gee.HashMap<string, Gtk.CssProvider> ();
        }

        var color = source_selectable.dup_color ();
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

    public async void reset_timer () {
        has_scrolled = true;
        Timeout.add (500, () => {
            has_scrolled = false;

            return false;
        });
    }
}
