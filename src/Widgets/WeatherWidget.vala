/*
 * Copyright (c) 2011-2015 Wingpanel Developers (http://launchpad.net/wingpanel)
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

public class DateTime.Widgets.WeatherWidget : Gtk.Button {
    private Gtk.Label button_label;

    private Gtk.Image button_image;
    private Gtk.Image tooltip_image;

    public WeatherWidget (string caption) {
        var content_widget = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_widget.hexpand = true;

        this.add (content_widget);

        button_image = create_image ();
        button_label = create_label_for_caption (caption);
        tooltip_image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.BUTTON);
        tooltip_image.margin_end = 6;
        tooltip_image.halign = Gtk.Align.END;

        content_widget.add (button_image);
        content_widget.add (button_label);
        content_widget.pack_end (tooltip_image);

        var style_context = this.get_style_context ();
        style_context.add_class (Gtk.STYLE_CLASS_MENUITEM);
        style_context.remove_class (Gtk.STYLE_CLASS_BUTTON);
        style_context.remove_class ("text-button");
    }

    public void set_caption (string caption) {
        button_label.set_label (Markup.escape_text (caption));
    }

    public string get_caption () {
        return button_label.get_label ();
    }

    public void set_icon (string? icon_name) {
        if (icon_name == null) {
            button_image.visible = false;
        } else {
            button_image.set_from_icon_name (icon_name, Gtk.IconSize.BUTTON);
            button_image.visible = true;
        }
    }

    public void set_information_tooltip (string text) {
        tooltip_image.set_tooltip_text (text);
    }

    public new Gtk.Label get_label () {
        return button_label;
    }

    private Gtk.Label create_label_for_caption (string caption, bool use_mnemonic = false) {
        Gtk.Label label_widget;

        if (use_mnemonic) {
            label_widget = new Gtk.Label.with_mnemonic (Markup.escape_text (caption));
            label_widget.set_mnemonic_widget (this);
        } else {
            label_widget = new Gtk.Label (Markup.escape_text (caption));
        }

        label_widget.use_markup = true;
        label_widget.halign = Gtk.Align.START;
        label_widget.margin_start = 6;
        label_widget.margin_end = 10;

        return label_widget;
    }

    private Gtk.Image create_image () {
        var image = new Gtk.Image ();
        image.margin_start = 6;
        image.no_show_all = true;
        image.visible = false;

        return image;
    }
}