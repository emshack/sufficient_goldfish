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
var KeyIndex_1 = require("../core/snap/indexes/KeyIndex");
var PriorityIndex_1 = require("../core/snap/indexes/PriorityIndex");
var ValueIndex_1 = require("../core/snap/indexes/ValueIndex");
var PathIndex_1 = require("../core/snap/indexes/PathIndex");
var util_2 = require("../core/util/util");
var Path_1 = require("../core/util/Path");
var validation_1 = require("../core/util/validation");
var util_3 = require("@firebase/util");
var EventRegistration_1 = require("../core/view/EventRegistration");
var util_4 = require("@firebase/util");
var __referenceConstructor;
/**
 * A Query represents a filter to be applied to a firebase location.  This object purely represents the
 * query expression (and exposes our public API to build the query).  The actual query logic is in ViewBase.js.
 *
 * Since every Firebase reference is a query, Firebase inherits from this object.
 */
var Query = /** @class */ (function () {
    function Query(repo, path, queryParams_, orderByCalled_) {
        this.repo = repo;
        this.path = path;
        this.queryParams_ = queryParams_;
        this.orderByCalled_ = orderByCalled_;
    }
    Object.defineProperty(Query, "__referenceConstructor", {
        get: function () {
            util_1.assert(__referenceConstructor, 'Reference.ts has not been loaded');
            return __referenceConstructor;
        },
        set: function (val) {
            __referenceConstructor = val;
        },
        enumerable: true,
        configurable: true
    });
    /**
     * Validates start/end values for queries.
     * @param {!QueryParams} params
     * @private
     */
    Query.validateQueryEndpoints_ = function (params) {
        var startNode = null;
        var endNode = null;
        if (params.hasStart()) {
            startNode = params.getIndexStartValue();
        }
        if (params.hasEnd()) {
            endNode = params.getIndexEndValue();
        }
        if (params.getIndex() === KeyIndex_1.KEY_INDEX) {
            var tooManyArgsError = 'Query: When ordering by key, you may only pass one argument to ' +
                'startAt(), endAt(), or equalTo().';
            var wrongArgTypeError = 'Query: When ordering by key, the argument passed to startAt(), endAt(),' +
                'or equalTo() must be a string.';
            if (params.hasStart()) {
                var startName = params.getIndexStartName();
                if (startName != util_2.MIN_NAME) {
                    throw new Error(tooManyArgsError);
                }
                else if (typeof startNode !== 'string') {
                    throw new Error(wrongArgTypeError);
                }
            }
            if (params.hasEnd()) {
                var endName = params.getIndexEndName();
                if (endName != util_2.MAX_NAME) {
                    throw new Error(tooManyArgsError);
                }
                else if (typeof endNode !== 'string') {
                    throw new Error(wrongArgTypeError);
                }
            }
        }
        else if (params.getIndex() === PriorityIndex_1.PRIORITY_INDEX) {
            if ((startNode != null && !validation_1.isValidPriority(startNode)) ||
                (endNode != null && !validation_1.isValidPriority(endNode))) {
                throw new Error('Query: When ordering by priority, the first argument passed to startAt(), ' +
                    'endAt(), or equalTo() must be a valid priority value (null, a number, or a string).');
            }
        }
        else {
            util_1.assert(params.getIndex() instanceof PathIndex_1.PathIndex ||
                params.getIndex() === ValueIndex_1.VALUE_INDEX, 'unknown index type.');
            if ((startNode != null && typeof startNode === 'object') ||
                (endNode != null && typeof endNode === 'object')) {
                throw new Error('Query: First argument passed to startAt(), endAt(), or equalTo() cannot be ' +
                    'an object.');
            }
        }
    };
    /**
     * Validates that limit* has been called with the correct combination of parameters
     * @param {!QueryParams} params
     * @private
     */
    Query.validateLimit_ = function (params) {
        if (params.hasStart() &&
            params.hasEnd() &&
            params.hasLimit() &&
            !params.hasAnchoredLimit()) {
            throw new Error("Query: Can't combine startAt(), endAt(), and limit(). Use limitToFirst() or limitToLast() instead.");
        }
    };
    /**
     * Validates that no other order by call has been made
     * @param {!string} fnName
     * @private
     */
    Query.prototype.validateNoPreviousOrderByCall_ = function (fnName) {
        if (this.orderByCalled_ === true) {
            throw new Error(fnName + ": You can't combine multiple orderBy calls.");
        }
    };
    /**
     * @return {!QueryParams}
     */
    Query.prototype.getQueryParams = function () {
        return this.queryParams_;
    };
    /**
     * @return {!Reference}
     */
    Query.prototype.getRef = function () {
        util_3.validateArgCount('Query.ref', 0, 0, arguments.length);
        // This is a slight hack. We cannot goog.require('fb.api.Firebase'), since Firebase requires fb.api.Query.
        // However, we will always export 'Firebase' to the global namespace, so it's guaranteed to exist by the time this
        // method gets called.
        return new Query.__referenceConstructor(this.repo, this.path);
    };
    /**
     * @param {!string} eventType
     * @param {!function(DataSnapshot, string=)} callback
     * @param {(function(Error)|Object)=} cancelCallbackOrContext
     * @param {Object=} context
     * @return {!function(DataSnapshot, string=)}
     */
    Query.prototype.on = function (eventType, callback, cancelCallbackOrContext, context) {
        util_3.validateArgCount('Query.on', 2, 4, arguments.length);
        validation_1.validateEventType('Query.on', 1, eventType, false);
        util_3.validateCallback('Query.on', 2, callback, false);
        var ret = Query.getCancelAndContextArgs_('Query.on', cancelCallbackOrContext, context);
        if (eventType === 'value') {
            this.onValueEvent(callback, ret.cancel, ret.context);
        }
        else {
            var callbacks = {};
            callbacks[eventType] = callback;
            this.onChildEvent(callbacks, ret.cancel, ret.context);
        }
        return callback;
    };
    /**
     * @param {!function(!DataSnapshot)} callback
     * @param {?function(Error)} cancelCallback
     * @param {?Object} context
     * @protected
     */
    Query.prototype.onValueEvent = function (callback, cancelCallback, context) {
        var container = new EventRegistration_1.ValueEventRegistration(callback, cancelCallback || null, context || null);
        this.repo.addEventCallbackForQuery(this, container);
    };
    /**
     * @param {!Object.<string, !function(!DataSnapshot, ?string)>} callbacks
     * @param {?function(Error)} cancelCallback
     * @param {?Object} context
     * @protected
     */
    Query.prototype.onChildEvent = function (callbacks, cancelCallback, context) {
        var container = new EventRegistration_1.ChildEventRegistration(callbacks, cancelCallback, context);
        this.repo.addEventCallbackForQuery(this, container);
    };
    /**
     * @param {string=} eventType
     * @param {(function(!DataSnapshot, ?string=))=} callback
     * @param {Object=} context
     */
    Query.prototype.off = function (eventType, callback, context) {
        util_3.validateArgCount('Query.off', 0, 3, arguments.length);
        validation_1.validateEventType('Query.off', 1, eventType, true);
        util_3.validateCallback('Query.off', 2, callback, true);
        util_3.validateContextObject('Query.off', 3, context, true);
        var container = null;
        var callbacks = null;
        if (eventType === 'value') {
            var valueCallback = callback || null;
            container = new EventRegistration_1.ValueEventRegistration(valueCallback, null, context || null);
        }
        else if (eventType) {
            if (callback) {
                callbacks = {};
                callbacks[eventType] = callback;
            }
            container = new EventRegistration_1.ChildEventRegistration(callbacks, null, context || null);
        }
        this.repo.removeEventCallbackForQuery(this, container);
    };
    /**
     * Attaches a listener, waits for the first event, and then removes the listener
     * @param {!string} eventType
     * @param {!function(!DataSnapshot, string=)} userCallback
     * @param cancelOrContext
     * @param context
     * @return {!firebase.Promise}
     */
    Query.prototype.once = function (eventType, userCallback, cancelOrContext, context) {
        var _this = this;
        util_3.validateArgCount('Query.once', 1, 4, arguments.length);
        validation_1.validateEventType('Query.once', 1, eventType, false);
        util_3.validateCallback('Query.once', 2, userCallback, true);
        var ret = Query.getCancelAndContextArgs_('Query.once', cancelOrContext, context);
        // TODO: Implement this more efficiently (in particular, use 'get' wire protocol for 'value' event)
        // TODO: consider actually wiring the callbacks into the promise. We cannot do this without a breaking change
        // because the API currently expects callbacks will be called synchronously if the data is cached, but this is
        // against the Promise specification.
        var firstCall = true;
        var deferred = new util_4.Deferred();
        // A dummy error handler in case a user wasn't expecting promises
        deferred.promise.catch(function () { });
        var onceCallback = function (snapshot) {
            // NOTE: Even though we unsubscribe, we may get called multiple times if a single action (e.g. set() with JSON)
            // triggers multiple events (e.g. child_added or child_changed).
            if (firstCall) {
                firstCall = false;
                _this.off(eventType, onceCallback);
                if (userCallback) {
                    userCallback.bind(ret.context)(snapshot);
                }
                deferred.resolve(snapshot);
            }
        };
        this.on(eventType, onceCallback, 
        /*cancel=*/ function (err) {
            _this.off(eventType, onceCallback);
            if (ret.cancel)
                ret.cancel.bind(ret.context)(err);
            deferred.reject(err);
        });
        return deferred.promise;
    };
    /**
     * Set a limit and anchor it to the start of the window.
     * @param {!number} limit
     * @return {!Query}
     */
    Query.prototype.limitToFirst = function (limit) {
        util_3.validateArgCount('Query.limitToFirst', 1, 1, arguments.length);
        if (typeof limit !== 'number' ||
            Math.floor(limit) !== limit ||
            limit <= 0) {
            throw new Error('Query.limitToFirst: First argument must be a positive integer.');
        }
        if (this.queryParams_.hasLimit()) {
            throw new Error('Query.limitToFirst: Limit was already set (by another call to limit, ' +
                'limitToFirst, or limitToLast).');
        }
        return new Query(this.repo, this.path, this.queryParams_.limitToFirst(limit), this.orderByCalled_);
    };
    /**
     * Set a limit and anchor it to the end of the window.
     * @param {!number} limit
     * @return {!Query}
     */
    Query.prototype.limitToLast = function (limit) {
        util_3.validateArgCount('Query.limitToLast', 1, 1, arguments.length);
        if (typeof limit !== 'number' ||
            Math.floor(limit) !== limit ||
            limit <= 0) {
            throw new Error('Query.limitToLast: First argument must be a positive integer.');
        }
        if (this.queryParams_.hasLimit()) {
            throw new Error('Query.limitToLast: Limit was already set (by another call to limit, ' +
                'limitToFirst, or limitToLast).');
        }
        return new Query(this.repo, this.path, this.queryParams_.limitToLast(limit), this.orderByCalled_);
    };
    /**
     * Given a child path, return a new query ordered by the specified grandchild path.
     * @param {!string} path
     * @return {!Query}
     */
    Query.prototype.orderByChild = function (path) {
        util_3.validateArgCount('Query.orderByChild', 1, 1, arguments.length);
        if (path === '$key') {
            throw new Error('Query.orderByChild: "$key" is invalid.  Use Query.orderByKey() instead.');
        }
        else if (path === '$priority') {
            throw new Error('Query.orderByChild: "$priority" is invalid.  Use Query.orderByPriority() instead.');
        }
        else if (path === '$value') {
            throw new Error('Query.orderByChild: "$value" is invalid.  Use Query.orderByValue() instead.');
        }
        validation_1.validatePathString('Query.orderByChild', 1, path, false);
        this.validateNoPreviousOrderByCall_('Query.orderByChild');
        var parsedPath = new Path_1.Path(path);
        if (parsedPath.isEmpty()) {
            throw new Error('Query.orderByChild: cannot pass in empty path.  Use Query.orderByValue() instead.');
        }
        var index = new PathIndex_1.PathIndex(parsedPath);
        var newParams = this.queryParams_.orderBy(index);
        Query.validateQueryEndpoints_(newParams);
        return new Query(this.repo, this.path, newParams, /*orderByCalled=*/ true);
    };
    /**
     * Return a new query ordered by the KeyIndex
     * @return {!Query}
     */
    Query.prototype.orderByKey = function () {
        util_3.validateArgCount('Query.orderByKey', 0, 0, arguments.length);
        this.validateNoPreviousOrderByCall_('Query.orderByKey');
        var newParams = this.queryParams_.orderBy(KeyIndex_1.KEY_INDEX);
        Query.validateQueryEndpoints_(newParams);
        return new Query(this.repo, this.path, newParams, /*orderByCalled=*/ true);
    };
    /**
     * Return a new query ordered by the PriorityIndex
     * @return {!Query}
     */
    Query.prototype.orderByPriority = function () {
        util_3.validateArgCount('Query.orderByPriority', 0, 0, arguments.length);
        this.validateNoPreviousOrderByCall_('Query.orderByPriority');
        var newParams = this.queryParams_.orderBy(PriorityIndex_1.PRIORITY_INDEX);
        Query.validateQueryEndpoints_(newParams);
        return new Query(this.repo, this.path, newParams, /*orderByCalled=*/ true);
    };
    /**
     * Return a new query ordered by the ValueIndex
     * @return {!Query}
     */
    Query.prototype.orderByValue = function () {
        util_3.validateArgCount('Query.orderByValue', 0, 0, arguments.length);
        this.validateNoPreviousOrderByCall_('Query.orderByValue');
        var newParams = this.queryParams_.orderBy(ValueIndex_1.VALUE_INDEX);
        Query.validateQueryEndpoints_(newParams);
        return new Query(this.repo, this.path, newParams, /*orderByCalled=*/ true);
    };
    /**
     * @param {number|string|boolean|null} value
     * @param {?string=} name
     * @return {!Query}
     */
    Query.prototype.startAt = function (value, name) {
        if (value === void 0) { value = null; }
        util_3.validateArgCount('Query.startAt', 0, 2, arguments.length);
        validation_1.validateFirebaseDataArg('Query.startAt', 1, value, this.path, true);
        validation_1.validateKey('Query.startAt', 2, name, true);
        var newParams = this.queryParams_.startAt(value, name);
        Query.validateLimit_(newParams);
        Query.validateQueryEndpoints_(newParams);
        if (this.queryParams_.hasStart()) {
            throw new Error('Query.startAt: Starting point was already set (by another call to startAt ' +
                'or equalTo).');
        }
        // Calling with no params tells us to start at the beginning.
        if (value === undefined) {
            value = null;
            name = null;
        }
        return new Query(this.repo, this.path, newParams, this.orderByCalled_);
    };
    /**
     * @param {number|string|boolean|null} value
     * @param {?string=} name
     * @return {!Query}
     */
    Query.prototype.endAt = function (value, name) {
        if (value === void 0) { value = null; }
        util_3.validateArgCount('Query.endAt', 0, 2, arguments.length);
        validation_1.validateFirebaseDataArg('Query.endAt', 1, value, this.path, true);
        validation_1.validateKey('Query.endAt', 2, name, true);
        var newParams = this.queryParams_.endAt(value, name);
        Query.validateLimit_(newParams);
        Query.validateQueryEndpoints_(newParams);
        if (this.queryParams_.hasEnd()) {
            throw new Error('Query.endAt: Ending point was already set (by another call to endAt or ' +
                'equalTo).');
        }
        return new Query(this.repo, this.path, newParams, this.orderByCalled_);
    };
    /**
     * Load the selection of children with exactly the specified value, and, optionally,
     * the specified name.
     * @param {number|string|boolean|null} value
     * @param {string=} name
     * @return {!Query}
     */
    Query.prototype.equalTo = function (value, name) {
        util_3.validateArgCount('Query.equalTo', 1, 2, arguments.length);
        validation_1.validateFirebaseDataArg('Query.equalTo', 1, value, this.path, false);
        validation_1.validateKey('Query.equalTo', 2, name, true);
        if (this.queryParams_.hasStart()) {
            throw new Error('Query.equalTo: Starting point was already set (by another call to startAt or ' +
                'equalTo).');
        }
        if (this.queryParams_.hasEnd()) {
            throw new Error('Query.equalTo: Ending point was already set (by another call to endAt or ' +
                'equalTo).');
        }
        return this.startAt(value, name).endAt(value, name);
    };
    /**
     * @return {!string} URL for this location.
     */
    Query.prototype.toString = function () {
        util_3.validateArgCount('Query.toString', 0, 0, arguments.length);
        return this.repo.toString() + this.path.toUrlEncodedString();
    };
    // Do not create public documentation. This is intended to make JSON serialization work but is otherwise unnecessary
    // for end-users.
    Query.prototype.toJSON = function () {
        // An optional spacer argument is unnecessary for a string.
        util_3.validateArgCount('Query.toJSON', 0, 1, arguments.length);
        return this.toString();
    };
    /**
     * An object representation of the query parameters used by this Query.
     * @return {!Object}
     */
    Query.prototype.queryObject = function () {
        return this.queryParams_.getQueryObject();
    };
    /**
     * @return {!string}
     */
    Query.prototype.queryIdentifier = function () {
        var obj = this.queryObject();
        var id = util_2.ObjectToUniqueKey(obj);
        return id === '{}' ? 'default' : id;
    };
    /**
     * Return true if this query and the provided query are equivalent; otherwise, return false.
     * @param {Query} other
     * @return {boolean}
     */
    Query.prototype.isEqual = function (other) {
        util_3.validateArgCount('Query.isEqual', 1, 1, arguments.length);
        if (!(other instanceof Query)) {
            var error = 'Query.isEqual failed: First argument must be an instance of firebase.database.Query.';
            throw new Error(error);
        }
        var sameRepo = this.repo === other.repo;
        var samePath = this.path.equals(other.path);
        var sameQueryIdentifier = this.queryIdentifier() === other.queryIdentifier();
        return sameRepo && samePath && sameQueryIdentifier;
    };
    /**
     * Helper used by .on and .once to extract the context and or cancel arguments.
     * @param {!string} fnName The function name (on or once)
     * @param {(function(Error)|Object)=} cancelOrContext
     * @param {Object=} context
     * @return {{cancel: ?function(Error), context: ?Object}}
     * @private
     */
    Query.getCancelAndContextArgs_ = function (fnName, cancelOrContext, context) {
        var ret = { cancel: null, context: null };
        if (cancelOrContext && context) {
            ret.cancel = cancelOrContext;
            util_3.validateCallback(fnName, 3, ret.cancel, true);
            ret.context = context;
            util_3.validateContextObject(fnName, 4, ret.context, true);
        }
        else if (cancelOrContext) {
            // we have either a cancel callback or a context.
            if (typeof cancelOrContext === 'object' && cancelOrContext !== null) {
                // it's a context!
                ret.context = cancelOrContext;
            }
            else if (typeof cancelOrContext === 'function') {
                ret.cancel = cancelOrContext;
            }
            else {
                throw new Error(util_3.errorPrefix(fnName, 3, true) +
                    ' must either be a cancel callback or a context object.');
            }
        }
        return ret;
    };
    Object.defineProperty(Query.prototype, "ref", {
        get: function () {
            return this.getRef();
        },
        enumerable: true,
        configurable: true
    });
    return Query;
}());
exports.Query = Query;

//# sourceMappingURL=Query.js.map
