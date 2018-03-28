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
import { isEmpty, getCount, forEach, contains } from '@firebase/util';
/**
 * Implements a set with a count of elements.
 *
 * @template K, V
 */
var CountedSet = /** @class */ (function () {
    function CountedSet() {
        this.set = {};
    }
    /**
     * @param {!K} item
     * @param {V} val
     */
    CountedSet.prototype.add = function (item, val) {
        this.set[item] = val !== null ? val : true;
    };
    /**
     * @param {!K} key
     * @return {boolean}
     */
    CountedSet.prototype.contains = function (key) {
        return contains(this.set, key);
    };
    /**
     * @param {!K} item
     * @return {V}
     */
    CountedSet.prototype.get = function (item) {
        return this.contains(item) ? this.set[item] : undefined;
    };
    /**
     * @param {!K} item
     */
    CountedSet.prototype.remove = function (item) {
        delete this.set[item];
    };
    /**
     * Deletes everything in the set
     */
    CountedSet.prototype.clear = function () {
        this.set = {};
    };
    /**
     * True if there's nothing in the set
     * @return {boolean}
     */
    CountedSet.prototype.isEmpty = function () {
        return isEmpty(this.set);
    };
    /**
     * @return {number} The number of items in the set
     */
    CountedSet.prototype.count = function () {
        return getCount(this.set);
    };
    /**
     * Run a function on each k,v pair in the set
     * @param {function(K, V)} fn
     */
    CountedSet.prototype.each = function (fn) {
        forEach(this.set, function (k, v) { return fn(k, v); });
    };
    /**
     * Mostly for debugging
     * @return {Array.<K>} The keys present in this CountedSet
     */
    CountedSet.prototype.keys = function () {
        var keys = [];
        forEach(this.set, function (k) {
            keys.push(k);
        });
        return keys;
    };
    return CountedSet;
}());
export { CountedSet };

//# sourceMappingURL=CountedSet.js.map
