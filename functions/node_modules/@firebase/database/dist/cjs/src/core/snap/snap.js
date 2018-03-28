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
var util_2 = require("../util/util");
var util_3 = require("@firebase/util");
var MAX_NODE;
function setMaxNode(val) {
    MAX_NODE = val;
}
exports.setMaxNode = setMaxNode;
/**
 * @param {(!string|!number)} priority
 * @return {!string}
 */
exports.priorityHashText = function (priority) {
    if (typeof priority === 'number')
        return 'number:' + util_2.doubleToIEEE754String(priority);
    else
        return 'string:' + priority;
};
/**
 * Validates that a priority snapshot Node is valid.
 *
 * @param {!Node} priorityNode
 */
exports.validatePriorityNode = function (priorityNode) {
    if (priorityNode.isLeafNode()) {
        var val = priorityNode.val();
        util_1.assert(typeof val === 'string' ||
            typeof val === 'number' ||
            (typeof val === 'object' && util_3.contains(val, '.sv')), 'Priority must be a string or number.');
    }
    else {
        util_1.assert(priorityNode === MAX_NODE || priorityNode.isEmpty(), 'priority of unexpected type.');
    }
    // Don't call getPriority() on MAX_NODE to avoid hitting assertion.
    util_1.assert(priorityNode === MAX_NODE || priorityNode.getPriority().isEmpty(), "Priority nodes can't have a priority of their own.");
};

//# sourceMappingURL=snap.js.map
