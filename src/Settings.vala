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
using Gee;

namespace ManjaroNews {

    // settings handling the config load / save
    public class Settings : Object {
        /* private fields */
        string config_file_path;
        string config_path;
        string items_path;
        string autostart_path;
        string home_path;
        public Config config;

        /* properties */
        public string icon_name_no_news {
            owned get {
                if (config.IconTheme == "System") {
                    return "mntray-regular";
                }
                return "matray-no-news-" + config.IconTheme.down ();
            }
        }
        public string icon_name_news {
            owned get {
                if (config.IconTheme == "System") {
                    return "mntray-news";
                }
                return "matray-news-" + config.IconTheme.down ();
            }
        }

        /* constants */
        const string RESOURCE_PATH_ICONS = "/org/moson/matray/icons/";
        const string RESOURCE_PATH_MISC = "/org/moson/matray/misc/";
        const string AUTOSTART_FILE = "autostart.desktop";
        const string AUTOSTART_OFF_FILE = "autostart_off.desktop";

        /* constructor */
        public Settings () {
            this.home_path = Environment.get_home_dir ();
            this.config_path = Environment.get_user_config_dir () + "/matray";
            this.config_file_path = config_path + "/config.json";
            this.items_path = config_path + "/news_items.json";
            this.autostart_path = Environment.get_user_config_dir () + "/autostart";
        }

        /* public methods */
        // creates new configuration file
        public bool new_config () {
            print ("Creating new default config file...\n");
            if (!create_directory (config_path)) {
                return false;
            }

            config = new Config.get_default ();

            return save_config ();
        }

        // load news from local items file
        public ArrayList<NewsItem> load_news_local () {
            var list = new ArrayList<NewsItem> ();
            try {
                string json;
                size_t len;
                FileUtils.get_contents (items_path, out json, out len);
                var parser = new Json.Parser ();
                parser.load_from_data (json, (ssize_t) len);
                var items = parser.get_root ().get_object ().get_array_member ("Items");
                foreach (var item in items.get_elements ()) {
                    var news_item = (NewsItem) Json.gobject_deserialize (typeof (NewsItem), item);
                    list.add (news_item);
                }
            } catch (Error e) {
                printerr ("Error reading items file: \n%s\n", e.message);
            }
            return list;
        }

        // save news items to local file
        public bool save_news_local (ArrayList<NewsItem> items) {
            try {
                size_t len;
                var item_collection = new ItemCollection ();
                item_collection.Items = items;
                var json = Json.gobject_to_data (item_collection, out len);
                FileUtils.set_contents (items_path, json, (ssize_t) len);
            } catch (Error e) {
                printerr ("Error writing items file: \n%s\n", e.message);
                return false;
            }
            return true;
        }

        // read configuration file
        public bool load_config () {
            string b;
            get_branch (out b);
            try {
                string conf;
                FileUtils.get_contents (config_file_path, out conf, null);

                config = (Config) Json.gobject_from_data (typeof (Config), conf);
            } catch (Error e) {
                printerr ("Error reading config file: \n%s\n", e.message);
                return false;
            }
            return true;
        }

        // write configuration file
        public bool save_config () {
            try {
                size_t len;
                config.Version = new Config.get_default ().Version;
                var conf = Json.gobject_to_data (config, out len);

                FileUtils.set_contents (config_file_path, conf, (ssize_t) len);
            } catch (Error e) {
                printerr ("Error writing config file: \n%s\n", e.message);
                return false;
            }
            return true;
        }

        // read branch from pacman-mirrors file
        public bool get_branch (out string branch) {
            branch = "could not detect branch";
            var pm_conf = File.new_for_path ("/etc/pacman-mirrors.conf");
            if (!pm_conf.query_exists ()) {
                return false;
            }

            try {
                var dis = new DataInputStream (pm_conf.read ());
                string line;
                while ((line = dis.read_line ()) != null) {
                    if (line.contains ("Branch") && line.contains ("=") && !line.contains ("#Branch")) {
                        var b = line.replace (" ", "").split ("=");
                        if (b.length > 1) {
                            branch = b[1];
                            return true;
                        }
                    }
                }
                printerr ("Could not detect branch from pacman-mirrors.conf");
                return false;
            } catch (Error e) {
                printerr ("Error detecting branch:\n" + e.message);
                return false;
            }
        }

        // create autostart file
        public void create_autostart_file (bool recreate) {
            if (!create_directory (config_path)) {
                return;
            }

            var dest_file_path = autostart_path + "/org.moson.matray.desktop";
            var dest_file = File.new_for_path (dest_file_path);
            if (!recreate && dest_file.query_exists ()) {
                return;
            }
            if (dest_file.query_exists ()) {
                try {
                    dest_file.delete ();
                } catch (Error e) {
                    printerr ("Error deleting autostart file: \n%s\n", e.message);
                    return;
                }
            }
            try {
                var bytes = resources_lookup_data (RESOURCE_PATH_MISC + AUTOSTART_FILE, ResourceLookupFlags.NONE).get_data ();
                if (!config.Autostart) {
                    bytes = resources_lookup_data (RESOURCE_PATH_MISC + AUTOSTART_OFF_FILE, ResourceLookupFlags.NONE).get_data ();
                }
                FileUtils.set_data (dest_file_path, bytes);
            } catch (Error e) {
                printerr ("Error creating autostart file: \n%s\n", e.message);
            }
        }

        /* private methods */
        // create directory
        private bool create_directory (string path) {
            var dir = File.new_for_path (path);
            if (!dir.query_exists ()) {
                try {
                    dir.make_directory_with_parents ();
                } catch (Error e) {
                    printerr ("Error creating directory: \n%s\n", e.message);
                    return false;
                }
            }
            return true;
        }
    }
}