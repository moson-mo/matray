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
    // data structure of news items saved to disk
    public class ItemCollection : Object, Json.Serializable {
        public unowned Gee.ArrayList<NewsItem> Items { get; set; }

        public Json.Node serialize_property (string property_name, Value @value, ParamSpec pspec) {
            if (@value.type ().is_a (typeof (ArrayList))) {
                unowned ArrayList<Object> list_value = @value as ArrayList<GLib.Object>;
                if (list_value != null || property_name == "data") {
                    var array = new Json.Array.sized (list_value.size);
                    foreach (var item in list_value) {
                        array.add_element (Json.gobject_serialize (item));
                    }

                    var node = new Json.Node (Json.NodeType.ARRAY);
                    node.set_array (array);
                    return node;
                }
            }
            return default_serialize_property (property_name, @value, pspec);
        }
    }
}