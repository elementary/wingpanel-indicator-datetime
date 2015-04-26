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

public class DateTime.Indicator : Wingpanel.Indicator {
	private Gtk.Label indicator_label;

	private Gtk.Grid main_grid;

	public Indicator () {
		Object (code_name: Indicator.DATETIME,
				display_name: _("Date & Time"),
				description:_("The date and time indicator"));
	}

	public override Gtk.Widget get_display_widget () {
		if (indicator_label == null) {
			indicator_label = new Gtk.Label ("hallo");
		}

		return indicator_label;
	}

	public override Gtk.Widget get_widget () {
		if (main_grid == null) {
			main_grid = new Gtk.Grid ();

			// TODO
		}

		// I do have something to display!
		this.visible = true;

		return main_grid;
	}

	public override void opened () {
		
	}

	public override void closed () {
		
	}
}

public Wingpanel.Indicator get_indicator (Module module) {
	debug ("Activating DateTime Indicator");
	var indicator = new DateTime.Indicator ();
	return indicator;
}
