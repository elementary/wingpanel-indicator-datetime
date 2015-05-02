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
	public PanelLabel () {
		update_time_label ();

		Services.TimeManager.get_default ().minute_changed.connect (update_time_label);
	}

	private void update_time_label () {
		this.set_label (Services.TimeManager.get_default ().format (_("%a, %d. %b  %I:%M %P")));
	}
}

