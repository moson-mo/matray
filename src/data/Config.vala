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

namespace ManjaroNews {
    // data structure for config file
    public class Config : Object {
        public string Version { get; set; }
        public string ServerURL { get; set; }
        public int MaxArticles { get; set; }
        public string[] AvailableCategories { get; set; }
        public string[] Categories { get; set; }
        public string[] AddCategoriesBranch { get; set; }
        public int RefreshInterval { get; set; }
        public bool HideNoNews { get; set; }
        public bool Autostart { get; set; }
        public bool ErrorNotifications { get; set; }
        public int DelayAfterStart { get; set; }
        public bool SetCategoriesFromBranch { get; set; }
        public string IconTheme { get; set; }

        // default config
        public Config.get_default () {
            this.Version = "1.1.1";
            this.ServerURL = "http://manjaro.moson.eu:10111/news";
            this.MaxArticles = 15;
            this.AvailableCategories = new string[] {
                "Testing Updates",
                "Stable Updates",
                "Stable Staging Updates",
                "Unstable Updates",
                "Twitter",
                "News",
                "Announcements",
                "Releases",
                "ARM News",
                "ARM Releases",
                "ARM Stable Updates",
                "ARM Testing Updates",
                "ARM Unstable Updates"
            };
            this.Categories = new string[] {
                "Stable Updates",
                "News",
                "Announcements",
                "Releases"
            };
            this.AddCategoriesBranch = new string[] {
                "News",
                "Announcements",
                "Releases"
            };
            this.RefreshInterval = 600;
            this.HideNoNews = false;
            this.Autostart = true;
            this.ErrorNotifications = true;
            this.DelayAfterStart = 10;
            this.SetCategoriesFromBranch = true;
            this.IconTheme = "Bright";
        }
    }
}