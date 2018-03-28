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
var app_1 = require("@firebase/app");
var Database_1 = require("./src/api/Database");
exports.Database = Database_1.Database;
var Query_1 = require("./src/api/Query");
exports.Query = Query_1.Query;
var Reference_1 = require("./src/api/Reference");
exports.Reference = Reference_1.Reference;
var util_1 = require("./src/core/util/util");
exports.enableLogging = util_1.enableLogging;
var RepoManager_1 = require("./src/core/RepoManager");
var INTERNAL = require("./src/api/internal");
var TEST_ACCESS = require("./src/api/test_access");
var util_2 = require("@firebase/util");
var ServerValue = Database_1.Database.ServerValue;
exports.ServerValue = ServerValue;
function registerDatabase(instance) {
    // Register the Database Service with the 'firebase' namespace.
    var namespace = instance.INTERNAL.registerService('database', function (app, unused, url) { return RepoManager_1.RepoManager.getInstance().databaseFromApp(app, url); }, 
    // firebase.database namespace properties
    {
        Reference: Reference_1.Reference,
        Query: Query_1.Query,
        Database: Database_1.Database,
        enableLogging: util_1.enableLogging,
        INTERNAL: INTERNAL,
        ServerValue: ServerValue,
        TEST_ACCESS: TEST_ACCESS
    }, null, true);
    if (util_2.isNodeSdk()) {
        module.exports = namespace;
    }
}
exports.registerDatabase = registerDatabase;
registerDatabase(app_1.default);
var DataSnapshot_1 = require("./src/api/DataSnapshot");
exports.DataSnapshot = DataSnapshot_1.DataSnapshot;
var onDisconnect_1 = require("./src/api/onDisconnect");
exports.OnDisconnect = onDisconnect_1.OnDisconnect;

//# sourceMappingURL=index.js.map
