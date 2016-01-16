/*
 * Copyright (c) 2011-2016 elementary Developers (https://launchpad.net/elementary)
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
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

public class DateTime.Services.SettingsManager : Granite.Services.Settings {
    private static SettingsManager? instance = null;

    public double[] location { get; set; }
    public bool show_weeks{ get; set; }

    public SettingsManager () {
        base ("org.pantheon.desktop.wingpanel.indicators.datetime");
    }

    public static SettingsManager get_default () {
        if (instance == null) {
            instance = new SettingsManager ();
        }

        return instance;
    }
}