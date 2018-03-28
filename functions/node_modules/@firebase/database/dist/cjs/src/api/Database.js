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
var tslib_1 = require("tslib");
var util_1 = require("../core/util/util");
var parser_1 = require("../core/util/libs/parser");
var Path_1 = require("../core/util/Path");
var Reference_1 = require("./Reference");
var Repo_1 = require("../core/Repo");
var RepoManager_1 = require("../core/RepoManager");
var util_2 = require("@firebase/util");
var validation_1 = require("../core/util/validation");
/**
 * Class representing a firebase database.
 * @implements {FirebaseService}
 */
var Database = /** @class */ (function () {
    /**
     * The constructor should not be called by users of our public API.
     * @param {!Repo} repo_
     */
    function Database(repo_) {
        this.repo_ = repo_;
        if (!(repo_ instanceof Repo_1.Repo)) {
            util_1.fatal("Don't call new Database() directly - please use firebase.database().");
        }
        /** @type {Reference} */
        this.root_ = new Reference_1.Reference(repo_, Path_1.Path.Empty);
        this.INTERNAL = new DatabaseInternals(this);
    }
    Object.defineProperty(Database.prototype, "app", {
        get: function () {
            return this.repo_.app;
        },
        enumerable: true,
        configurable: true
    });
    Database.prototype.ref = function (path) {
        this.checkDeleted_('ref');
        util_2.validateArgCount('database.ref', 0, 1, arguments.length);
        if (path instanceof Reference_1.Reference) {
            return this.refFromURL(path.toString());
        }
        return path !== undefined ? this.root_.child(path) : this.root_;
    };
    /**
     * Returns a reference to the root or the path specified in url.
     * We throw a exception if the url is not in the same domain as the
     * current repo.
     * @param {string} url
     * @return {!Reference} Firebase reference.
     */
    Database.prototype.refFromURL = function (url) {
        /** @const {string} */
        var apiName = 'database.refFromURL';
        this.checkDeleted_(apiName);
        util_2.validateArgCount(apiName, 1, 1, arguments.length);
        var parsedURL = parser_1.parseRepoInfo(url);
        validation_1.validateUrl(apiName, 1, parsedURL);
        var repoInfo = parsedURL.repoInfo;
        if (repoInfo.host !== this.repo_.repoInfo_.host) {
            util_1.fatal(apiName +
                ': Host name does not match the current database: ' +
                '(found ' +
                repoInfo.host +
                ' but expected ' +
                this.repo_.repoInfo_.host +
                ')');
        }
        return this.ref(parsedURL.path.toString());
    };
    /**
     * @param {string} apiName
     */
    Database.prototype.checkDeleted_ = function (apiName) {
        if (this.repo_ === null) {
            util_1.fatal('Cannot call ' + apiName + ' on a deleted database.');
        }
    };
    // Make individual repo go offline.
    Database.prototype.goOffline = function () {
        util_2.validateArgCount('database.goOffline', 0, 0, arguments.length);
        this.checkDeleted_('goOffline');
        this.repo_.interrupt();
    };
    Database.prototype.goOnline = function () {
        util_2.validateArgCount('database.goOnline', 0, 0, arguments.length);
        this.checkDeleted_('goOnline');
        this.repo_.resume();
    };
    Database.ServerValue = {
        TIMESTAMP: {
            '.sv': 'timestamp'
        }
    };
    return Database;
}());
exports.Database = Database;
var DatabaseInternals = /** @class */ (function () {
    /** @param {!Database} database */
    function DatabaseInternals(database) {
        this.database = database;
    }
    /** @return {Promise<void>} */
    DatabaseInternals.prototype.delete = function () {
        return tslib_1.__awaiter(this, void 0, void 0, function () {
            return tslib_1.__generator(this, function (_a) {
                this.database.checkDeleted_('delete');
                RepoManager_1.RepoManager.getInstance().deleteRepo(this.database.repo_);
                this.database.repo_ = null;
                this.database.root_ = null;
                this.database.INTERNAL = null;
                this.database = null;
                return [2 /*return*/];
            });
        });
    };
    return DatabaseInternals;
}());
exports.DatabaseInternals = DatabaseInternals;

//# sourceMappingURL=Database.js.map
