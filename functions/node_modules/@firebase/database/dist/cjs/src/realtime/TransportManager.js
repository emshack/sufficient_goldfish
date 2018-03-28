"use strict";
/**
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
Object.defineProperty(exports, "__esModule", { value: true });
var BrowserPollConnection_1 = require("./BrowserPollConnection");
var WebSocketConnection_1 = require("./WebSocketConnection");
var util_1 = require("../core/util/util");
/**
 * Currently simplistic, this class manages what transport a Connection should use at various stages of its
 * lifecycle.
 *
 * It starts with longpolling in a browser, and httppolling on node. It then upgrades to websockets if
 * they are available.
 * @constructor
 */
var TransportManager = /** @class */ (function () {
    /**
     * @param {!RepoInfo} repoInfo Metadata around the namespace we're connecting to
     */
    function TransportManager(repoInfo) {
        this.initTransports_(repoInfo);
    }
    Object.defineProperty(TransportManager, "ALL_TRANSPORTS", {
        /**
         * @const
         * @type {!Array.<function(new:Transport, string, RepoInfo, string=)>}
         */
        get: function () {
            return [BrowserPollConnection_1.BrowserPollConnection, WebSocketConnection_1.WebSocketConnection];
        },
        enumerable: true,
        configurable: true
    });
    /**
     * @param {!RepoInfo} repoInfo
     * @private
     */
    TransportManager.prototype.initTransports_ = function (repoInfo) {
        var isWebSocketsAvailable = WebSocketConnection_1.WebSocketConnection && WebSocketConnection_1.WebSocketConnection['isAvailable']();
        var isSkipPollConnection = isWebSocketsAvailable && !WebSocketConnection_1.WebSocketConnection.previouslyFailed();
        if (repoInfo.webSocketOnly) {
            if (!isWebSocketsAvailable)
                util_1.warn("wss:// URL used, but browser isn't known to support websockets.  Trying anyway.");
            isSkipPollConnection = true;
        }
        if (isSkipPollConnection) {
            this.transports_ = [WebSocketConnection_1.WebSocketConnection];
        }
        else {
            var transports_1 = (this.transports_ = []);
            util_1.each(TransportManager.ALL_TRANSPORTS, function (i, transport) {
                if (transport && transport['isAvailable']()) {
                    transports_1.push(transport);
                }
            });
        }
    };
    /**
     * @return {function(new:Transport, !string, !RepoInfo, string=, string=)} The constructor for the
     * initial transport to use
     */
    TransportManager.prototype.initialTransport = function () {
        if (this.transports_.length > 0) {
            return this.transports_[0];
        }
        else {
            throw new Error('No transports available');
        }
    };
    /**
     * @return {?function(new:Transport, function(),function(), string=)} The constructor for the next
     * transport, or null
     */
    TransportManager.prototype.upgradeTransport = function () {
        if (this.transports_.length > 1) {
            return this.transports_[1];
        }
        else {
            return null;
        }
    };
    return TransportManager;
}());
exports.TransportManager = TransportManager;

//# sourceMappingURL=TransportManager.js.map
