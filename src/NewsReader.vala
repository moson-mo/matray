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
    // NewsReader class
    public class NewsReader : Object {
        /* private fields */
        Soup.Session session;
        Soup.Message message;
        TimeZone tz;
        Settings settings;
        uint timeout_id;

        /* properties */
        public bool is_running { get; private set; }

        /* public fields */
        public ArrayList<NewsItem> news_items { get; set; }

        /* signals */
        public signal void error_occurred (string message);
        public signal void news_fetched ();

        /* constructor */
        public NewsReader (Settings settings) {
            this.settings = settings;
            this.tz = new TimeZone.utc ();
            this.news_items = new ArrayList<NewsItem>((a, b) => {
                return a.GUID == b.GUID;
            });

            session = new Soup.Session ();
            session.timeout = 5;

            timeout_id = 0;
            is_running = false;
        }

        /* public methods */
        // start fetching news
        public void start () {
            is_running = true;
            construct_request ();
            fetch_news ();
            if (timeout_id == 0) {
                timeout_id = Timeout.add_seconds (settings.config.RefreshInterval, fetch_news);
            }
        }

        // stop fetching news
        public void stop () {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }
            is_running = false;
        }

        public NewsItem get_latest_item () {
            NewsItem latest = new NewsItem ();
            latest.PublishedDateUnix = 0;

            foreach (var item in news_items) {
                if (item.PublishedDateUnix > latest.PublishedDateUnix) {
                    latest = item;
                }
            }
            return latest;
        }

        // remove all items that are not needed since they exceed our maximum number of items
        public void remove_obsolete_items () {
            if (is_running) {       // actually quite useless. I do know it won't be running when this executes :)
                return;
            }
            if (news_items.size > settings.config.MaxArticles) {
                news_items.sort ((a, b) => {
                    return (int) (b.PublishedDateUnix - a.PublishedDateUnix);
                });
                news_items.remove_all (news_items.slice (settings.config.MaxArticles, news_items.size));
            }
        }

        /* private methods */
        // construct http post request for fetching news from server
        private void construct_request () {
            size_t mlen;
            var r = new Request ();
            r.MaxItems = settings.config.MaxArticles;
            r.Categories = get_desired_categories ();

            var json_string = Json.gobject_to_data (r, out mlen);
            message = new Soup.Message ("POST", settings.config.ServerURL);
            message.set_request ("application/json", Soup.MemoryUse.COPY, json_string.data);
        }

        // return list of categories to fetch news for
        private string[] get_desired_categories () {
            if (!settings.config.SetCategoriesFromBranch) {
                return settings.config.Categories;
            } else {
                return get_branch_categories ();
            }
        }

        // return branch specific list of categories; including additional ones
        private string[] get_branch_categories () {
            ArrayList<string> categories = new ArrayList<string> ();
            string branch;

            // get current branch
            if (settings.get_branch (out branch)) {
                branch = branch.replace ("arm-", "arm ");
            } else {
                branch = "stable";
            }

            // add additional categories
            foreach (var additional_category in settings.config.AddCategoriesBranch) {
                categories.add (additional_category);
            }

            // add branch specific category
            foreach (var available_category in settings.config.AvailableCategories) {
                if (available_category.down () == branch + " updates") {
                    categories.add (available_category);
                }
            }

            return categories.to_array ();
        }

        // fetch news from server and add them to our list
        private bool fetch_news () {
            // queue / send POST request
            session.queue_message (message, (session, msg) => {
                // error :(
                if (msg.status_code != 200) {
                    printerr ("Error occurred fetching news:\n%s\n", msg.reason_phrase);
                    error_occurred (msg.reason_phrase);
                    return;
                }
                // parse json and add news item is not yet in list
                try {
                    var new_items = Json.from_string ((string) msg.response_body.data).get_array ();
                    var found = new ArrayList<NewsItem> ((a, b) => {
                        return a.GUID == b.GUID;
                    });
                    var to_remove = new ArrayList<NewsItem> ();
                    
                    foreach (var item_element in new_items.get_elements ()) {
                        var new_item = (NewsItem) Json.gobject_deserialize (typeof (NewsItem), item_element);
                        var date = new DateTime.from_iso8601 (new_item.PublishedDate, tz);
                        new_item.PublishedDateUnix = date.to_unix ();
                        found.add (new_item);

                        if (!news_items.contains (new_item)) {
                            news_items.add (new_item); 
                        }
                    }
                    
                    // remove all entries that do not exists anymore
                    foreach(var item in news_items) {
                        if (!found.contains (item)) {
                            to_remove.add (item);
                        }
                    }
                    news_items.remove_all (to_remove);
                    
                    news_fetched ();
                } catch (Error err) {
                    printerr (err.message);
                }
            });
            return true;
        }

        // remove all items from our list that do not match our list of categories
        private void remove_unmatched_items () {
            ArrayList<string> wanted = new ArrayList<string> ();
            ArrayList<NewsItem> to_remove = new ArrayList<NewsItem> ();
            wanted.add_all_array (get_desired_categories ());

            foreach (var item in news_items) {
                if (!wanted.contains (item.Category)) {
                    to_remove.add (item);
                }
            }
            news_items.remove_all (to_remove);
        }
    }
}