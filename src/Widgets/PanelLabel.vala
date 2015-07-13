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

public class DateTime.Widgets.PanelLabel : Gtk.Box {
	private Gtk.Label date_label;
	private Gtk.Label time_label;

	public PanelLabel () {
		Object (orientation: Gtk.Orientation.HORIZONTAL);

		build_ui ();

		update_labels ();

		Services.TimeManager.get_default ().minute_changed.connect (update_labels);
	}

	private void build_ui () {
		date_label = new Gtk.Label (null);
		time_label = new Gtk.Label (null);

		date_label.margin_end = 12;

		this.add (date_label);
		this.add (time_label);
	}

	private void update_labels () {
		date_label.set_label (Services.TimeManager.get_default ().format (_("%a, %d. %b")));
		time_label.set_label (Services.TimeManager.get_default ().format (_("%I:%M %P")));
	}
}
