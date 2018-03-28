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
var onDisconnect_1 = require("./onDisconnect");
var TransactionResult_1 = require("./TransactionResult");
var util_1 = require("../core/util/util");
var NextPushId_1 = require("../core/util/NextPushId");
var Query_1 = require("./Query");
var Repo_1 = require("../core/Repo");
var Path_1 = require("../core/util/Path");
var QueryParams_1 = require("../core/view/QueryParams");
var validation_1 = require("../core/util/validation");
var util_2 = require("@firebase/util");
var util_3 = require("@firebase/util");
var SyncPoint_1 = require("../core/SyncPoint");
var Reference = /** @class */ (function (_super) {
    tslib_1.__extends(Reference, _super);
    /**
     * Call options:
     *   new Reference(Repo, Path) or
     *   new Reference(url: string, string|RepoManager)
     *
     * Externally - this is the firebase.database.Reference type.
     *
     * @param {!Repo} repo
     * @param {(!Path)} path
     * @extends {Query}
     */
    function Reference(repo, path) {
        var _this = this;
        if (!(repo instanceof Repo_1.Repo)) {
            throw new Error('new Reference() no longer supported - use app.database().');
        }
        // call Query's constructor, passing in the repo and path.
        _this = _super.call(this, repo, path, QueryParams_1.QueryParams.DEFAULT, false) || this;
        return _this;
    }
    /** @return {?string} */
    Reference.prototype.getKey = function () {
        util_2.validateArgCount('Reference.key', 0, 0, arguments.length);
        if (this.path.isEmpty())
            return null;
        else
            return this.path.getBack();
    };
    /**
     * @param {!(string|Path)} pathString
     * @return {!Reference}
     */
    Reference.prototype.child = function (pathString) {
        util_2.validateArgCount('Reference.child', 1, 1, arguments.length);
        if (typeof pathString === 'number') {
            pathString = String(pathString);
        }
        else if (!(pathString instanceof Path_1.Path)) {
            if (this.path.getFront() === null)
                validation_1.validateRootPathString('Reference.child', 1, pathString, false);
            else
                validation_1.validatePathString('Reference.child', 1, pathString, false);
        }
        return new Reference(this.repo, this.path.child(pathString));
    };
    /** @return {?Reference} */
    Reference.prototype.getParent = function () {
        util_2.validateArgCount('Reference.parent', 0, 0, arguments.length);
        var parentPath = this.path.parent();
        return parentPath === null ? null : new Reference(this.repo, parentPath);
    };
    /** @return {!Reference} */
    Reference.prototype.getRoot = function () {
        util_2.validateArgCount('Reference.root', 0, 0, arguments.length);
        var ref = this;
        while (ref.getParent() !== null) {
            ref = ref.getParent();
        }
        return ref;
    };
    /** @return {!Database} */
    Reference.prototype.databaseProp = function () {
        return this.repo.database;
    };
    /**
     * @param {*} newVal
     * @param {function(?Error)=} onComplete
     * @return {!Promise}
     */
    Reference.prototype.set = function (newVal, onComplete) {
        util_2.validateArgCount('Reference.set', 1, 2, arguments.length);
        validation_1.validateWritablePath('Reference.set', this.path);
        validation_1.validateFirebaseDataArg('Reference.set', 1, newVal, this.path, false);
        util_2.validateCallback('Reference.set', 2, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo.setWithPriority(this.path, newVal, 
        /*priority=*/ null, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {!Object} objectToMerge
     * @param {function(?Error)=} onComplete
     * @return {!Promise}
     */
    Reference.prototype.update = function (objectToMerge, onComplete) {
        util_2.validateArgCount('Reference.update', 1, 2, arguments.length);
        validation_1.validateWritablePath('Reference.update', this.path);
        if (Array.isArray(objectToMerge)) {
            var newObjectToMerge = {};
            for (var i = 0; i < objectToMerge.length; ++i) {
                newObjectToMerge['' + i] = objectToMerge[i];
            }
            objectToMerge = newObjectToMerge;
            util_1.warn('Passing an Array to Firebase.update() is deprecated. ' +
                'Use set() if you want to overwrite the existing data, or ' +
                'an Object with integer keys if you really do want to ' +
                'only update some of the children.');
        }
        validation_1.validateFirebaseMergeDataArg('Reference.update', 1, objectToMerge, this.path, false);
        util_2.validateCallback('Reference.update', 2, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo.update(this.path, objectToMerge, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {*} newVal
     * @param {string|number|null} newPriority
     * @param {function(?Error)=} onComplete
     * @return {!Promise}
     */
    Reference.prototype.setWithPriority = function (newVal, newPriority, onComplete) {
        util_2.validateArgCount('Reference.setWithPriority', 2, 3, arguments.length);
        validation_1.validateWritablePath('Reference.setWithPriority', this.path);
        validation_1.validateFirebaseDataArg('Reference.setWithPriority', 1, newVal, this.path, false);
        validation_1.validatePriority('Reference.setWithPriority', 2, newPriority, false);
        util_2.validateCallback('Reference.setWithPriority', 3, onComplete, true);
        if (this.getKey() === '.length' || this.getKey() === '.keys')
            throw 'Reference.setWithPriority failed: ' +
                this.getKey() +
                ' is a read-only object.';
        var deferred = new util_3.Deferred();
        this.repo.setWithPriority(this.path, newVal, newPriority, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {function(?Error)=} onComplete
     * @return {!Promise}
     */
    Reference.prototype.remove = function (onComplete) {
        util_2.validateArgCount('Reference.remove', 0, 1, arguments.length);
        validation_1.validateWritablePath('Reference.remove', this.path);
        util_2.validateCallback('Reference.remove', 1, onComplete, true);
        return this.set(null, onComplete);
    };
    /**
     * @param {function(*):*} transactionUpdate
     * @param {(function(?Error, boolean, ?DataSnapshot))=} onComplete
     * @param {boolean=} applyLocally
     * @return {!Promise}
     */
    Reference.prototype.transaction = function (transactionUpdate, onComplete, applyLocally) {
        util_2.validateArgCount('Reference.transaction', 1, 3, arguments.length);
        validation_1.validateWritablePath('Reference.transaction', this.path);
        util_2.validateCallback('Reference.transaction', 1, transactionUpdate, false);
        util_2.validateCallback('Reference.transaction', 2, onComplete, true);
        // NOTE: applyLocally is an internal-only option for now.  We need to decide if we want to keep it and how
        // to expose it.
        validation_1.validateBoolean('Reference.transaction', 3, applyLocally, true);
        if (this.getKey() === '.length' || this.getKey() === '.keys')
            throw 'Reference.transaction failed: ' +
                this.getKey() +
                ' is a read-only object.';
        if (applyLocally === undefined)
            applyLocally = true;
        var deferred = new util_3.Deferred();
        if (typeof onComplete === 'function') {
            deferred.promise.catch(function () { });
        }
        var promiseComplete = function (error, committed, snapshot) {
            if (error) {
                deferred.reject(error);
            }
            else {
                deferred.resolve(new TransactionResult_1.TransactionResult(committed, snapshot));
            }
            if (typeof onComplete === 'function') {
                onComplete(error, committed, snapshot);
            }
        };
        this.repo.startTransaction(this.path, transactionUpdate, promiseComplete, applyLocally);
        return deferred.promise;
    };
    /**
     * @param {string|number|null} priority
     * @param {function(?Error)=} onComplete
     * @return {!Promise}
     */
    Reference.prototype.setPriority = function (priority, onComplete) {
        util_2.validateArgCount('Reference.setPriority', 1, 2, arguments.length);
        validation_1.validateWritablePath('Reference.setPriority', this.path);
        validation_1.validatePriority('Reference.setPriority', 1, priority, false);
        util_2.validateCallback('Reference.setPriority', 2, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo.setWithPriority(this.path.child('.priority'), priority, null, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {*=} value
     * @param {function(?Error)=} onComplete
     * @return {!Reference}
     */
    Reference.prototype.push = function (value, onComplete) {
        util_2.validateArgCount('Reference.push', 0, 2, arguments.length);
        validation_1.validateWritablePath('Reference.push', this.path);
        validation_1.validateFirebaseDataArg('Reference.push', 1, value, this.path, true);
        util_2.validateCallback('Reference.push', 2, onComplete, true);
        var now = this.repo.serverTime();
        var name = NextPushId_1.nextPushId(now);
        // push() returns a ThennableReference whose promise is fulfilled with a regular Reference.
        // We use child() to create handles to two different references. The first is turned into a
        // ThennableReference below by adding then() and catch() methods and is used as the
        // return value of push(). The second remains a regular Reference and is used as the fulfilled
        // value of the first ThennableReference.
        var thennablePushRef = this.child(name);
        var pushRef = this.child(name);
        var promise;
        if (value != null) {
            promise = thennablePushRef.set(value, onComplete).then(function () { return pushRef; });
        }
        else {
            promise = Promise.resolve(pushRef);
        }
        thennablePushRef.then = promise.then.bind(promise);
        thennablePushRef.catch = promise.then.bind(promise, undefined);
        if (typeof onComplete === 'function') {
            promise.catch(function () { });
        }
        return thennablePushRef;
    };
    /**
     * @return {!OnDisconnect}
     */
    Reference.prototype.onDisconnect = function () {
        validation_1.validateWritablePath('Reference.onDisconnect', this.path);
        return new onDisconnect_1.OnDisconnect(this.repo, this.path);
    };
    Object.defineProperty(Reference.prototype, "database", {
        get: function () {
            return this.databaseProp();
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Reference.prototype, "key", {
        get: function () {
            return this.getKey();
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Reference.prototype, "parent", {
        get: function () {
            return this.getParent();
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(Reference.prototype, "root", {
        get: function () {
            return this.getRoot();
        },
        enumerable: true,
        configurable: true
    });
    return Reference;
}(Query_1.Query));
exports.Reference = Reference;
/**
 * Define reference constructor in various modules
 *
 * We are doing this here to avoid several circular
 * dependency issues
 */
Query_1.Query.__referenceConstructor = Reference;
SyncPoint_1.SyncPoint.__referenceConstructor = Reference;

//# sourceMappingURL=Reference.js.map
