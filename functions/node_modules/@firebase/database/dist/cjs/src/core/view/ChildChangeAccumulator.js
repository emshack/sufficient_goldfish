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
var Change_1 = require("./Change");
var util_2 = require("@firebase/util");
/**
 * @constructor
 */
var ChildChangeAccumulator = /** @class */ (function () {
    function ChildChangeAccumulator() {
        this.changeMap_ = {};
    }
    /**
     * @param {!Change} change
     */
    ChildChangeAccumulator.prototype.trackChildChange = function (change) {
        var type = change.type;
        var childKey /** @type {!string} */ = change.childName;
        util_2.assert(type == Change_1.Change.CHILD_ADDED ||
            type == Change_1.Change.CHILD_CHANGED ||
            type == Change_1.Change.CHILD_REMOVED, 'Only child changes supported for tracking');
        util_2.assert(childKey !== '.priority', 'Only non-priority child changes can be tracked.');
        var oldChange = util_1.safeGet(this.changeMap_, childKey);
        if (oldChange) {
            var oldType = oldChange.type;
            if (type == Change_1.Change.CHILD_ADDED && oldType == Change_1.Change.CHILD_REMOVED) {
                this.changeMap_[childKey] = Change_1.Change.childChangedChange(childKey, change.snapshotNode, oldChange.snapshotNode);
            }
            else if (type == Change_1.Change.CHILD_REMOVED &&
                oldType == Change_1.Change.CHILD_ADDED) {
                delete this.changeMap_[childKey];
            }
            else if (type == Change_1.Change.CHILD_REMOVED &&
                oldType == Change_1.Change.CHILD_CHANGED) {
                this.changeMap_[childKey] = Change_1.Change.childRemovedChange(childKey, oldChange.oldSnap);
            }
            else if (type == Change_1.Change.CHILD_CHANGED &&
                oldType == Change_1.Change.CHILD_ADDED) {
                this.changeMap_[childKey] = Change_1.Change.childAddedChange(childKey, change.snapshotNode);
            }
            else if (type == Change_1.Change.CHILD_CHANGED &&
                oldType == Change_1.Change.CHILD_CHANGED) {
                this.changeMap_[childKey] = Change_1.Change.childChangedChange(childKey, change.snapshotNode, oldChange.oldSnap);
            }
            else {
                throw util_2.assertionError('Illegal combination of changes: ' +
                    change +
                    ' occurred after ' +
                    oldChange);
            }
        }
        else {
            this.changeMap_[childKey] = change;
        }
    };
    /**
     * @return {!Array.<!Change>}
     */
    ChildChangeAccumulator.prototype.getChanges = function () {
        return util_1.getValues(this.changeMap_);
    };
    return ChildChangeAccumulator;
}());
exports.ChildChangeAccumulator = ChildChangeAccumulator;

//# sourceMappingURL=ChildChangeAccumulator.js.map
