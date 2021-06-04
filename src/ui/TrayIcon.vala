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
using AppIndicator;

namespace ManjaroNews {

    // application class constructing tray icon
    public class TrayIcon : Gtk.Application {
        /* private fields */
        Gtk.Menu menu;
        NewsReader news_reader;
        Settings settings;
        bool running;
        bool delay;
        Indicator icon;

        /* delegates */
        delegate void ExecFunc ();

        /* constructor */
        public TrayIcon (bool delay) {
            application_id = "org.moson.matray";
            flags = ApplicationFlags.FLAGS_NONE;
            register_session = true;

            this.delay = delay;
            shutdown.connect (quit_app);
            query_end.connect (this.release);
            Environment.set_application_name ("matray");
        }

        /* here we go */
        protected override void activate () {
            // Translations
            Intl.setlocale (LocaleCategory.ALL, "");
            Intl.textdomain ("matray");

            // prevent second instance from loading
            if (running) {
                return;
            }
            running = true;

            // GNOME just sucks
            var gtk_settings = Gtk.Settings.get_default ();
            gtk_settings.gtk_menu_images = true;
            gtk_settings.gtk_button_images = true;

            // handle graceful shutdown on SIGINT / SIGTERM
            Unix.signal_add (Posix.Signal.INT, on_unix_signal, Priority.DEFAULT);
            Unix.signal_add (Posix.Signal.TERM, on_unix_signal, Priority.DEFAULT);
            Unix.signal_add (Posix.Signal.HUP, on_unix_signal, Priority.DEFAULT);

            // load config
            settings = new Settings ();
            if (!settings.load_config ()) {
                settings.new_config ();
            }
            settings.create_autostart_file (false);

            // ugly hack for KDE - wait 5 seconds before attempting to create systray icon
            if (delay) {
                Thread.usleep (5 * 1000 * 1000);
            }

            // set up tray icon
            icon = new Indicator ("matray", settings.icon_name_no_news, IndicatorCategory.APPLICATION_STATUS);
            icon.set_status (IndicatorStatus.ACTIVE);

            // start news reader
            news_reader = new NewsReader (settings);
            news_reader.news_items.add_all (settings.load_news_local ());
            set_tray_icon ();
            news_reader.error_occured.connect (on_nr_error_occured);
            news_reader.news_fetched.connect (on_nr_news_fetched);

            // if --delay was given as argument, delay startup of newsreader
            if (delay) {
                Timeout.add_seconds (settings.config.DelayAfterStart, () => {
                    news_reader.start ();
                    return false;
                });
            } else {
                news_reader.start ();
            }

            // create tray menu
            menu = new Gtk.Menu ();
            menu.menu_type_hint = Gdk.WindowTypeHint.POPUP_MENU;
            create_menu ();
            icon.set_menu (menu);

            print ("\nmatray started.\n");

            this.hold ();
        }

        /* private methods */
        // save config and quit application
        private void quit_app () {
            news_reader.stop ();
            news_reader.remove_obsolete_items ();
            settings.save_config ();
            settings.save_news_local (news_reader.news_items);
        }

        // create and send notification
        private void new_notification (string title, string body, ICON_TYPE icon_type) {
            var notification = new Notification (title);

            try {
                string ico_string;
                if (icon_type == ICON_TYPE.ERROR) {
                    ico_string = icon_type.to_string ();
                } else {
                    ico_string = settings.icon_name_news;
                }
                var ico = Icon.new_for_string (ico_string);
                notification.set_icon (ico);
            } catch (Error e) {
                printerr ("Error setting notification icon: %s\n", e.message);
            }

            notification.set_body (body);
            this.send_notification (null, notification);
        }

        //
        private bool on_unix_signal () {
            this.release ();
            return Source.REMOVE;
        }

        // signal callback - when error occured
        private void on_nr_error_occured (string message) {
            if (settings.config.ErrorNotifications) {
                var err_msg = _("Error occured fetching news:") + "\n\n" + message;
                new_notification (_("Error"), err_msg, ICON_TYPE.ERROR);
            }
        }

        // signal callback - when news have been fetched
        private void on_nr_news_fetched () {
            foreach (var news_item in news_reader.news_items) {
                if (!news_item.NotificationSent) {
                    new_notification ("Manjaro news", news_item.Title, ICON_TYPE.NEWS);
                    news_item.NotificationSent = true;
                }
            }
            create_menu ();
            set_tray_icon ();
            settings.save_news_local (news_reader.news_items);
        }

        // check if all items have been read and set icon accordingly
        private void set_tray_icon () {
            foreach (var item in news_reader.news_items) {
                if (!item.WasOpened) {
                    icon.set_icon_full (settings.icon_name_news, "News availale!");
                    icon.title = _("News available!");
                    if (settings.config.HideNoNews) {
                        icon.set_status (IndicatorStatus.ACTIVE);
                    }
                    return;
                }
            }
            icon.set_icon_full (settings.icon_name_no_news, "No news");
            icon.title = _("No news");
            if (settings.config.HideNoNews) {
                icon.set_status (IndicatorStatus.PASSIVE);
            }
        }

        // create tray menu
        private void create_menu () {
            clear_menu ();

            // add separator menu item
            var separator = new SeparatorMenuItem ();
            separator.set_data ("is_news", false);
            menu.append (separator);

            // add "mark all as read" menu item
            add_menu_item (_("Mark all as read"), "emblem-checked", () => {
                foreach (var item in news_reader.news_items) {
                    item.WasOpened = true;
                }
                set_tray_icon ();
                settings.save_news_local (news_reader.news_items);
                create_menu ();
            });

            // add settings menu item
            add_menu_item (_("Settings"), "repository", () => {
                news_reader.stop (); // stop reading news: when settings change we don't need to refresh
                var settings_win = new SettingsWindow (settings);
                settings_win.show_all ();
                settings_win.delete_event.connect (() => { // start reading news again after setting changes
                    set_tray_icon ();
                    news_reader.start ();
                    return false;
                });
            });

            // add about menu item
            add_menu_item (_("About"), "dialog-information", () => {
                var about_win = new AboutWindow ();
                about_win.show_all ();
            });

            // add separator before quit menu item
            var separator_quit = new SeparatorMenuItem ();
            separator_quit.set_data ("is_news", false);
            menu.append (separator_quit);

            // add quit menu item -> save all settings and news items to disk
            add_menu_item (_("Quit"), "gtk-quit", this.release);

            // add all news items to menu
            foreach (var item in news_reader.news_items) {
                add_news_menu_item (item);
            }

            menu.show_all ();
        }

        // remove everything from menu
        private void clear_menu () {
            var children = menu.get_children ();

            for (int i = 0; i < children.length (); i++) {
                menu.remove (children.nth_data (i));
            }
        }

        // add a non-news item to the tray menu
        private void add_menu_item (string title, string ? icon_name, ExecFunc exec_func) {
            var menu_item = new Gtk.MenuItem ();
            var box = new Box (Orientation.HORIZONTAL, 5);
            var label = new Label (title);
            var image = new Image ();
            if (icon_name != null) {
                image = new Image.from_icon_name (icon_name, IconSize.MENU);
            }

            box.add (image);
            box.add (label);
            menu_item.add (box);

            menu_item.set_data ("is_news", false);
            menu_item.activate.connect (() => {
                exec_func ();
            });
            menu.append (menu_item);
        }

        // add a news item to the tray menu
        public void add_news_menu_item (NewsItem item) {
            Image icon;
            var menu_item = new Gtk.MenuItem ();
            var box = new Box (Orientation.HORIZONTAL, 5);
            var label = new Label (item.Title);
            var icon_name = "emblem-remove";
            if (item.WasOpened) {
                icon_name = "emblem-checked";
            }
            icon = new Image.from_icon_name (icon_name, IconSize.MENU);

            box.add (icon);
            box.add (label);
            menu_item.add (box);

            menu_item.set_data ("news_item", item);
            menu_item.set_data ("is_news", true);
            menu_item.set_data ("sort", item.PublishedDateUnix);

            // when clicked, open browser
            menu_item.activate.connect (() => {
                try {
                    Process.spawn_command_line_async ("xdg-open " + item.URL);
                } catch (Error e) {
                    printerr ("Error spawning process: \n%s\n", e.message);
                }

                item.WasOpened = true;
                set_tray_icon ();
                settings.save_news_local (news_reader.news_items);
                create_menu ();
            });

            // insert item and make sure we don't show more than the max setting
            menu.insert (menu_item, get_menu_insert_position (item));

            if (menu.get_children ().length () > settings.config.MaxArticles + 6) {
                menu.remove (menu.get_children ().nth_data (settings.config.MaxArticles));
            }
        }

        // get position where to insert menu item (date descending)
        private int get_menu_insert_position (NewsItem new_item) {
            var current_position = 0;

            foreach (var menu_item in menu.get_children ()) {
                if (!menu_item.get_data<bool>("is_news") || new_item.PublishedDateUnix > menu_item.get_data<NewsItem>("news_item").PublishedDateUnix) {
                    return current_position;
                }
                current_position++;
            }
            return current_position;
        }
    }
}