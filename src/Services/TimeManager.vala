/*-
 * Copyright (c) 2015 Wingpanel Developers (http://launchpad.net/wingpanel)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Library General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class DateTime.Services.TimeManager : Gtk.Calendar {
	private static TimeManager? instance = null;

	public signal void minute_changed ();

	private GLib.DateTime? current_time = null;

	public TimeManager () {
		update_current_time ();

		if (current_time == null)
			return;

		var seconds_until_next_minute = 60 - (current_time.to_unix () % 60);

		Timeout.add ((uint)seconds_until_next_minute * 1000, () => {
			update_current_time ();
			minute_changed ();

			Timeout.add (60 * 1000, () => {
				update_current_time ();
				minute_changed ();

				return true;
			});

			return false;
		});
	}

	public string format (string format) {
		if (current_time == null)
			return "undef";

		return current_time.format (format);
	}

	public GLib.DateTime get_current_time () {
		return current_time;
	}

	private void update_current_time () {
		var local_time = new GLib.DateTime.now_local ();

		if (local_time == null) {
			critical ("Can't get the local time.");

			return;
		}

		current_time = local_time;
	}

	public static TimeManager get_default () {
		if (instance == null)
			instance = new TimeManager ();

		return instance;
	}
}
