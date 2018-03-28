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
import { RepoInfo } from '../core/RepoInfo';
import { PersistentConnection } from '../core/PersistentConnection';
import { RepoManager } from '../core/RepoManager';
import { Connection } from '../realtime/Connection';
export var DataConnection = PersistentConnection;
/**
 * @param {!string} pathString
 * @param {function(*)} onComplete
 */
PersistentConnection.prototype.simpleListen = function (pathString, onComplete) {
    this.sendRequest('q', { p: pathString }, onComplete);
};
/**
 * @param {*} data
 * @param {function(*)} onEcho
 */
PersistentConnection.prototype.echo = function (data, onEcho) {
    this.sendRequest('echo', { d: data }, onEcho);
};
// RealTimeConnection properties that we use in tests.
export var RealTimeConnection = Connection;
/**
 * @param {function(): string} newHash
 * @return {function()}
 */
export var hijackHash = function (newHash) {
    var oldPut = PersistentConnection.prototype.put;
    PersistentConnection.prototype.put = function (pathString, data, opt_onComplete, opt_hash) {
        if (opt_hash !== undefined) {
            opt_hash = newHash();
        }
        oldPut.call(this, pathString, data, opt_onComplete, opt_hash);
    };
    return function () {
        PersistentConnection.prototype.put = oldPut;
    };
};
/**
 * @type {function(new:RepoInfo, !string, boolean, !string, boolean): undefined}
 */
export var ConnectionTarget = RepoInfo;
/**
 * @param {!Query} query
 * @return {!string}
 */
export var queryIdentifier = function (query) {
    return query.queryIdentifier();
};
/**
 * @param {!Query} firebaseRef
 * @return {!Object}
 */
export var listens = function (firebaseRef) {
    return firebaseRef.repo.persistentConnection_.listens_;
};
/**
 * Forces the RepoManager to create Repos that use ReadonlyRestClient instead of PersistentConnection.
 *
 * @param {boolean} forceRestClient
 */
export var forceRestClient = function (forceRestClient) {
    RepoManager.getInstance().forceRestClient(forceRestClient);
};

//# sourceMappingURL=test_access.js.map
