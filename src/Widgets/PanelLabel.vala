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

public class DateTime.Widgets.PanelLabel : Gtk.Label {
	private const int UPDATE_TIME = 60 * 60;

	public PanelLabel () {
		update_time_display ();

		Timeout.add (UPDATE_TIME, update_time_display);
	}

	private bool update_time_display () {
		var local_time = new GLib.DateTime.now_local ();

		if (local_time == null) {
			critical ("Can't get the local time.");
			return false;
		}

		var time_string = local_time.format (_("%a, %d. %b  %I:%M %P"));

		this.set_label (time_string);

		return true;
	}
}

