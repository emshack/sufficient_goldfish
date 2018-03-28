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
var util_1 = require("@firebase/util");
var Repo_1 = require("./Repo");
var util_2 = require("./util/util");
var parser_1 = require("./util/libs/parser");
var validation_1 = require("./util/validation");
require("./Repo_transaction");
/** @const {string} */
var DATABASE_URL_OPTION = 'databaseURL';
var _staticInstance;
/**
 * Creates and caches Repo instances.
 */
var RepoManager = /** @class */ (function () {
    function RepoManager() {
        /**
         * @private {!Object.<string, Object<string, !fb.core.Repo>>}
         */
        this.repos_ = {};
        /**
         * If true, new Repos will be created to use ReadonlyRestClient (for testing purposes).
         * @private {boolean}
         */
        this.useRestClient_ = false;
    }
    RepoManager.getInstance = function () {
        if (!_staticInstance) {
            _staticInstance = new RepoManager();
        }
        return _staticInstance;
    };
    // TODO(koss): Remove these functions unless used in tests?
    RepoManager.prototype.interrupt = function () {
        for (var appName in this.repos_) {
            for (var dbUrl in this.repos_[appName]) {
                this.repos_[appName][dbUrl].interrupt();
            }
        }
    };
    RepoManager.prototype.resume = function () {
        for (var appName in this.repos_) {
            for (var dbUrl in this.repos_[appName]) {
                this.repos_[appName][dbUrl].resume();
            }
        }
    };
    /**
     * This function should only ever be called to CREATE a new database instance.
     *
     * @param {!FirebaseApp} app
     * @return {!Database}
     */
    RepoManager.prototype.databaseFromApp = function (app, url) {
        var dbUrl = url || app.options[DATABASE_URL_OPTION];
        if (dbUrl === undefined) {
            util_2.fatal("Can't determine Firebase Database URL.  Be sure to include " +
                DATABASE_URL_OPTION +
                ' option when calling firebase.initializeApp().');
        }
        var parsedUrl = parser_1.parseRepoInfo(dbUrl);
        var repoInfo = parsedUrl.repoInfo;
        validation_1.validateUrl('Invalid Firebase Database URL', 1, parsedUrl);
        if (!parsedUrl.path.isEmpty()) {
            util_2.fatal('Database URL must point to the root of a Firebase Database ' +
                '(not including a child path).');
        }
        var repo = this.createRepo(repoInfo, app);
        return repo.database;
    };
    /**
     * Remove the repo and make sure it is disconnected.
     *
     * @param {!Repo} repo
     */
    RepoManager.prototype.deleteRepo = function (repo) {
        var appRepos = util_1.safeGet(this.repos_, repo.app.name);
        // This should never happen...
        if (!appRepos || util_1.safeGet(appRepos, repo.repoInfo_.toURLString()) !== repo) {
            util_2.fatal("Database " + repo.app.name + "(" + repo.repoInfo_ + ") has already been deleted.");
        }
        repo.interrupt();
        delete appRepos[repo.repoInfo_.toURLString()];
    };
    /**
     * Ensures a repo doesn't already exist and then creates one using the
     * provided app.
     *
     * @param {!RepoInfo} repoInfo The metadata about the Repo
     * @param {!FirebaseApp} app
     * @return {!Repo} The Repo object for the specified server / repoName.
     */
    RepoManager.prototype.createRepo = function (repoInfo, app) {
        var appRepos = util_1.safeGet(this.repos_, app.name);
        if (!appRepos) {
            appRepos = {};
            this.repos_[app.name] = appRepos;
        }
        var repo = util_1.safeGet(appRepos, repoInfo.toURLString());
        if (repo) {
            util_2.fatal('Database initialized multiple times. Please make sure the format of the database URL matches with each database() call.');
        }
        repo = new Repo_1.Repo(repoInfo, this.useRestClient_, app);
        appRepos[repoInfo.toURLString()] = repo;
        return repo;
    };
    /**
     * Forces us to use ReadonlyRestClient instead of PersistentConnection for new Repos.
     * @param {boolean} forceRestClient
     */
    RepoManager.prototype.forceRestClient = function (forceRestClient) {
        this.useRestClient_ = forceRestClient;
    };
    return RepoManager;
}());
exports.RepoManager = RepoManager;

//# sourceMappingURL=RepoManager.js.map
