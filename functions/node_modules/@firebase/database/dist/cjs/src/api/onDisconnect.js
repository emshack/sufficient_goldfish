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
var validation_1 = require("../core/util/validation");
var util_2 = require("../core/util/util");
var util_3 = require("@firebase/util");
/**
 * @constructor
 */
var OnDisconnect = /** @class */ (function () {
    /**
     * @param {!Repo} repo_
     * @param {!Path} path_
     */
    function OnDisconnect(repo_, path_) {
        this.repo_ = repo_;
        this.path_ = path_;
    }
    /**
     * @param {function(?Error)=} onComplete
     * @return {!firebase.Promise}
     */
    OnDisconnect.prototype.cancel = function (onComplete) {
        util_1.validateArgCount('OnDisconnect.cancel', 0, 1, arguments.length);
        util_1.validateCallback('OnDisconnect.cancel', 1, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo_.onDisconnectCancel(this.path_, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {function(?Error)=} onComplete
     * @return {!firebase.Promise}
     */
    OnDisconnect.prototype.remove = function (onComplete) {
        util_1.validateArgCount('OnDisconnect.remove', 0, 1, arguments.length);
        validation_1.validateWritablePath('OnDisconnect.remove', this.path_);
        util_1.validateCallback('OnDisconnect.remove', 1, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo_.onDisconnectSet(this.path_, null, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {*} value
     * @param {function(?Error)=} onComplete
     * @return {!firebase.Promise}
     */
    OnDisconnect.prototype.set = function (value, onComplete) {
        util_1.validateArgCount('OnDisconnect.set', 1, 2, arguments.length);
        validation_1.validateWritablePath('OnDisconnect.set', this.path_);
        validation_1.validateFirebaseDataArg('OnDisconnect.set', 1, value, this.path_, false);
        util_1.validateCallback('OnDisconnect.set', 2, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo_.onDisconnectSet(this.path_, value, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {*} value
     * @param {number|string|null} priority
     * @param {function(?Error)=} onComplete
     * @return {!firebase.Promise}
     */
    OnDisconnect.prototype.setWithPriority = function (value, priority, onComplete) {
        util_1.validateArgCount('OnDisconnect.setWithPriority', 2, 3, arguments.length);
        validation_1.validateWritablePath('OnDisconnect.setWithPriority', this.path_);
        validation_1.validateFirebaseDataArg('OnDisconnect.setWithPriority', 1, value, this.path_, false);
        validation_1.validatePriority('OnDisconnect.setWithPriority', 2, priority, false);
        util_1.validateCallback('OnDisconnect.setWithPriority', 3, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo_.onDisconnectSetWithPriority(this.path_, value, priority, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    /**
     * @param {!Object} objectToMerge
     * @param {function(?Error)=} onComplete
     * @return {!firebase.Promise}
     */
    OnDisconnect.prototype.update = function (objectToMerge, onComplete) {
        util_1.validateArgCount('OnDisconnect.update', 1, 2, arguments.length);
        validation_1.validateWritablePath('OnDisconnect.update', this.path_);
        if (Array.isArray(objectToMerge)) {
            var newObjectToMerge = {};
            for (var i = 0; i < objectToMerge.length; ++i) {
                newObjectToMerge['' + i] = objectToMerge[i];
            }
            objectToMerge = newObjectToMerge;
            util_2.warn('Passing an Array to firebase.database.onDisconnect().update() is deprecated. Use set() if you want to overwrite the ' +
                'existing data, or an Object with integer keys if you really do want to only update some of the children.');
        }
        validation_1.validateFirebaseMergeDataArg('OnDisconnect.update', 1, objectToMerge, this.path_, false);
        util_1.validateCallback('OnDisconnect.update', 2, onComplete, true);
        var deferred = new util_3.Deferred();
        this.repo_.onDisconnectUpdate(this.path_, objectToMerge, deferred.wrapCallback(onComplete));
        return deferred.promise;
    };
    return OnDisconnect;
}());
exports.OnDisconnect = OnDisconnect;

//# sourceMappingURL=onDisconnect.js.map
