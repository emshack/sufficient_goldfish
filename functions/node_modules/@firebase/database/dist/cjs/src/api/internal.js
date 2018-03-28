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
var WebSocketConnection_1 = require("../realtime/WebSocketConnection");
var BrowserPollConnection_1 = require("../realtime/BrowserPollConnection");
/**
 * INTERNAL methods for internal-use only (tests, etc.).
 *
 * Customers shouldn't use these or else should be aware that they could break at any time.
 *
 * @const
 */
exports.forceLongPolling = function () {
    WebSocketConnection_1.WebSocketConnection.forceDisallow();
    BrowserPollConnection_1.BrowserPollConnection.forceAllow();
};
exports.forceWebSockets = function () {
    BrowserPollConnection_1.BrowserPollConnection.forceDisallow();
};
/* Used by App Manager */
exports.isWebSocketsAvailable = function () {
    return WebSocketConnection_1.WebSocketConnection['isAvailable']();
};
exports.setSecurityDebugCallback = function (ref, callback) {
    ref.repo.persistentConnection_.securityDebugCallback_ = callback;
};
exports.stats = function (ref, showDelta) {
    ref.repo.stats(showDelta);
};
exports.statsIncrementCounter = function (ref, metric) {
    ref.repo.statsIncrementCounter(metric);
};
exports.dataUpdateCount = function (ref) {
    return ref.repo.dataUpdateCount;
};
exports.interceptServerData = function (ref, callback) {
    return ref.repo.interceptServerData_(callback);
};

//# sourceMappingURL=internal.js.map
