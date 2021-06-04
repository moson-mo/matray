/*
 * Copyright (c) 2021, Mario Oenning <mo-son[at]mailbox[dot]org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

using GLib;
using Gtk;

namespace ManjaroNews {

    // settings window
    [GtkTemplate (ui = "/org/moson/matray/ui/SettingsWindow.ui")]
    public class SettingsWindow : ApplicationWindow {
        /* private fields */
        Settings settings;
        bool previous_autostart_setting;

        /* private UI fields */
        [GtkChild]
        private unowned Entry entry_server_url;

        [GtkChild]
        private unowned SpinButton sb_max_articles;

        [GtkChild]
        private unowned SpinButton sb_refresh_interval;

        [GtkChild]
        private unowned SpinButton sb_start_delay;

        [GtkChild]
        private unowned CheckButton chk_autostart;

        [GtkChild]
        private unowned CheckButton chk_error_notifications;

        [GtkChild]
        private unowned CheckButton chk_hide_read;

        [GtkChild]
        private unowned CheckButton chk_set_branch_categories;

        [GtkChild]
        private unowned ListBox lb_selected_categories;

        [GtkChild]
        private unowned Label lbl_selected_categories;

        [GtkChild]
        private unowned Label lbl_current_branch;

        [GtkChild]
        private unowned RadioButton rbtn_bright;

        [GtkChild]
        private unowned RadioButton rbtn_dark;

        [GtkChild]
        private unowned RadioButton rbtn_colorful;

        [GtkChild]
        private unowned RadioButton rbtn_system;

        /* signals */
        [GtkCallback]
        private void btn_save_clicked (Button btn) {
            safe_ui_values ();
        }

        [GtkCallback]
        private void btn_cancel_clicked (Button btn) {
            this.close ();
        }

        [GtkCallback]
        private void btn_reset_clicked (Button btn) {
            fill_controls ();
        }

        [GtkCallback]
        private void chk_set_branch_categories_toggled (ToggleButton btn) {
            fill_branch_control ();
        }

        /* constructor */
        public SettingsWindow (Settings settings) {
            this.settings = settings;

            fill_controls ();
        }

        /* private methods */
        // set UI field values from config
        private void fill_controls () {
            previous_autostart_setting = settings.config.Autostart;
            entry_server_url.text = settings.config.ServerURL;
            sb_max_articles.value = settings.config.MaxArticles;
            sb_refresh_interval.value = settings.config.RefreshInterval;
            sb_start_delay.value = settings.config.DelayAfterStart;

            chk_autostart.active = settings.config.Autostart;
            chk_error_notifications.active = settings.config.ErrorNotifications;
            chk_hide_read.active = settings.config.HideNoNews;
            chk_set_branch_categories.active = settings.config.SetCategoriesFromBranch;

            switch (settings.config.IconTheme) {
            case "Bright":
                rbtn_bright.active = true;
                break;
            case "Dark":
                rbtn_dark.active = true;
                break;
            case "Colorful":
                rbtn_colorful.active = true;
                break;
            default:
                rbtn_system.active = true;
                break;
            }

            fill_branch_control ();
        }

        // set UI field values for the branch specific controls
        private void fill_branch_control () {
            clear_category_listbox ();
            string branch;
            if (settings.get_branch (out branch)) {
                lbl_current_branch.label = _("Current branch: ") + branch;
            } else {
                lbl_current_branch.label = _("Could not detect branch!");
            }

            if (!chk_set_branch_categories.active) {
                lbl_selected_categories.label = "Selected categories";
                foreach (var cat in settings.config.AvailableCategories) {
                    var cb = new CheckButton.with_label (cat);
                    lb_selected_categories.add (cb);
                    foreach (var ecat in settings.config.Categories) {
                        if (ecat == cat) {
                            cb.active = true;
                        }
                    }
                }
            } else {
                lbl_selected_categories.label = _("Additional categories");
                foreach (var cat in settings.config.AvailableCategories) {
                    if (cat.contains (" Updates")) {
                        continue;
                    }
                    var cb = new CheckButton.with_label (cat);
                    lb_selected_categories.add (cb);
                    foreach (var ecat in settings.config.AddCategoriesBranch) {
                        if (ecat == cat) {
                            cb.active = true;
                        }
                    }
                }
            }
            lb_selected_categories.show_all ();
        }

        // clear categories from listbox
        private void clear_category_listbox () {
            foreach (var child in lb_selected_categories.get_children ()) {
                lb_selected_categories.remove (child);
            }
        }

        // apply values in controls to config
        private void safe_ui_values () {
            settings.config.ServerURL = entry_server_url.text;
            settings.config.MaxArticles = sb_max_articles.get_value_as_int ();
            settings.config.RefreshInterval = sb_refresh_interval.get_value_as_int ();
            settings.config.DelayAfterStart = sb_start_delay.get_value_as_int ();

            settings.config.Autostart = chk_autostart.active;
            settings.config.ErrorNotifications = chk_error_notifications.active;
            settings.config.HideNoNews = chk_hide_read.active;
            settings.config.SetCategoriesFromBranch = chk_set_branch_categories.active;

            if (rbtn_bright.active) {
                settings.config.IconTheme = "Bright";
            } else if (rbtn_dark.active) {
                settings.config.IconTheme = "Dark";
            } else if (rbtn_colorful.active) {
                settings.config.IconTheme = "Colorful";
            } else {
                settings.config.IconTheme = "System";
            }

            safe_ui_category_values ();

            settings.save_config ();

            if (previous_autostart_setting != settings.config.Autostart) {
                settings.create_autostart_file (true);
            }

            this.close ();
        }

        // apply values in category control to config
        private void safe_ui_category_values () {
            Gee.ArrayList<string> selected_categories = new Gee.ArrayList<string> ();
            foreach (var child in lb_selected_categories.get_children ()) {
                var lbr = (ListBoxRow) child;
                var cb = (CheckButton) lbr.get_children ().nth_data (0);
                if (cb.active) {
                    selected_categories.add (cb.label);
                }
            }

            if (!chk_set_branch_categories.active) {
                settings.config.Categories = selected_categories.to_array ();
            } else {
                settings.config.AddCategoriesBranch = selected_categories.to_array ();
            }
        }
    }
}