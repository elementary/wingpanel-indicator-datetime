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
	private const string SETTINGS_EXEC = "/usr/bin/switchboard datetime";

	private Widgets.PanelLabel panel_label;

	private Gtk.Grid main_grid;

	private Wingpanel.Widgets.Button today_button;

	private Widgets.Calendar calendar;

	private Wingpanel.Widgets.Button settings_button;

	public Indicator () {
		Object (code_name: Wingpanel.Indicator.DATETIME,
				display_name: _("Date & Time"),
				description:_("The date and time indicator"));
	}

	public override Gtk.Widget get_display_widget () {
		if (panel_label == null) {
			panel_label = new Widgets.PanelLabel ();
		}

		return panel_label;
	}

	public override Gtk.Widget? get_widget () {
		if (main_grid == null) {
			main_grid = new Gtk.Grid ();

			today_button = new Wingpanel.Widgets.Button ("");
			today_button.clicked.connect (() => {
				calendar.show_today ();
			});

			main_grid.attach (today_button, 0, 0, 1, 1);

			calendar = new Widgets.Calendar ();
			calendar.date_doubleclicked.connect (() => {
				this.close ();
			});

			main_grid.attach (calendar, 0, 1, 1, 1);

			settings_button = new Wingpanel.Widgets.Button (_("Date &amp; Time Settings…"));
			settings_button.clicked.connect (() => {
				show_settings ();
				this.close ();
			});

			main_grid.attach (new Wingpanel.Widgets.Separator (), 0, 2, 1, 1);

			main_grid.attach (settings_button, 0, 3, 1, 1);
		}

		// I do have something to display!
		this.visible = true;

		return main_grid;
	}

	public override void opened () {
		update_today_button ();
		Services.TimeManager.get_default ().minute_changed.connect (update_today_button);
	}

	public override void closed () {
		Services.TimeManager.get_default ().minute_changed.disconnect (update_today_button);
	}

	private void update_today_button () {
		today_button.set_caption (Services.TimeManager.get_default ().format (_("%A, %d. %B %Y")));
	}

	private void show_settings () {
		var cmd = new Granite.Services.SimpleCommand ("/usr/bin", SETTINGS_EXEC);
		cmd.run ();
	}
}

public Wingpanel.Indicator get_indicator (Module module) {
	debug ("Activating DateTime Indicator");
	var indicator = new DateTime.Indicator ();
	return indicator;
}
