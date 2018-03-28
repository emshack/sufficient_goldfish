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
var Path_1 = require("../core/util/Path");
var PriorityIndex_1 = require("../core/snap/indexes/PriorityIndex");
/**
 * Class representing a firebase data snapshot.  It wraps a SnapshotNode and
 * surfaces the public methods (val, forEach, etc.) we want to expose.
 */
var DataSnapshot = /** @class */ (function () {
    /**
     * @param {!Node} node_ A SnapshotNode to wrap.
     * @param {!Reference} ref_ The ref of the location this snapshot came from.
     * @param {!Index} index_ The iteration order for this snapshot
     */
    function DataSnapshot(node_, ref_, index_) {
        this.node_ = node_;
        this.ref_ = ref_;
        this.index_ = index_;
    }
    /**
     * Retrieves the snapshot contents as JSON.  Returns null if the snapshot is
     * empty.
     *
     * @return {*} JSON representation of the DataSnapshot contents, or null if empty.
     */
    DataSnapshot.prototype.val = function () {
        util_1.validateArgCount('DataSnapshot.val', 0, 0, arguments.length);
        return this.node_.val();
    };
    /**
     * Returns the snapshot contents as JSON, including priorities of node.  Suitable for exporting
     * the entire node contents.
     * @return {*} JSON representation of the DataSnapshot contents, or null if empty.
     */
    DataSnapshot.prototype.exportVal = function () {
        util_1.validateArgCount('DataSnapshot.exportVal', 0, 0, arguments.length);
        return this.node_.val(true);
    };
    // Do not create public documentation. This is intended to make JSON serialization work but is otherwise unnecessary
    // for end-users
    DataSnapshot.prototype.toJSON = function () {
        // Optional spacer argument is unnecessary because we're depending on recursion rather than stringifying the content
        util_1.validateArgCount('DataSnapshot.toJSON', 0, 1, arguments.length);
        return this.exportVal();
    };
    /**
     * Returns whether the snapshot contains a non-null value.
     *
     * @return {boolean} Whether the snapshot contains a non-null value, or is empty.
     */
    DataSnapshot.prototype.exists = function () {
        util_1.validateArgCount('DataSnapshot.exists', 0, 0, arguments.length);
        return !this.node_.isEmpty();
    };
    /**
     * Returns a DataSnapshot of the specified child node's contents.
     *
     * @param {!string} childPathString Path to a child.
     * @return {!DataSnapshot} DataSnapshot for child node.
     */
    DataSnapshot.prototype.child = function (childPathString) {
        util_1.validateArgCount('DataSnapshot.child', 0, 1, arguments.length);
        // Ensure the childPath is a string (can be a number)
        childPathString = String(childPathString);
        validation_1.validatePathString('DataSnapshot.child', 1, childPathString, false);
        var childPath = new Path_1.Path(childPathString);
        var childRef = this.ref_.child(childPath);
        return new DataSnapshot(this.node_.getChild(childPath), childRef, PriorityIndex_1.PRIORITY_INDEX);
    };
    /**
     * Returns whether the snapshot contains a child at the specified path.
     *
     * @param {!string} childPathString Path to a child.
     * @return {boolean} Whether the child exists.
     */
    DataSnapshot.prototype.hasChild = function (childPathString) {
        util_1.validateArgCount('DataSnapshot.hasChild', 1, 1, arguments.length);
        validation_1.validatePathString('DataSnapshot.hasChild', 1, childPathString, false);
        var childPath = new Path_1.Path(childPathString);
        return !this.node_.getChild(childPath).isEmpty();
    };
    /**
     * Returns the priority of the object, or null if no priority was set.
     *
     * @return {string|number|null} The priority.
     */
    DataSnapshot.prototype.getPriority = function () {
        util_1.validateArgCount('DataSnapshot.getPriority', 0, 0, arguments.length);
        // typecast here because we never return deferred values or internal priorities (MAX_PRIORITY)
        return this.node_.getPriority().val();
    };
    /**
     * Iterates through child nodes and calls the specified action for each one.
     *
     * @param {function(!DataSnapshot)} action Callback function to be called
     * for each child.
     * @return {boolean} True if forEach was canceled by action returning true for
     * one of the child nodes.
     */
    DataSnapshot.prototype.forEach = function (action) {
        var _this = this;
        util_1.validateArgCount('DataSnapshot.forEach', 1, 1, arguments.length);
        util_1.validateCallback('DataSnapshot.forEach', 1, action, false);
        if (this.node_.isLeafNode())
            return false;
        var childrenNode = this.node_;
        // Sanitize the return value to a boolean. ChildrenNode.forEachChild has a weird return type...
        return !!childrenNode.forEachChild(this.index_, function (key, node) {
            return action(new DataSnapshot(node, _this.ref_.child(key), PriorityIndex_1.PRIORITY_INDEX));
        });
    };
    /**
     * Returns whether this DataSnapshot has children.
     * @return {boolean} True if the DataSnapshot contains 1 or more child nodes.
     */
    DataSnapshot.prototype.hasChildren = function () {
        util_1.validateArgCount('DataSnapshot.hasChildren', 0, 0, arguments.length);
        if (this.node_.isLeafNode())
            return false;
        else
            return !this.node_.isEmpty();
    };
    Object.defineProperty(DataSnapshot.prototype, "key", {
        get: function () {
            return this.ref_.getKey();
        },
        enumerable: true,
        configurable: true
    });
    /**
     * Returns the number of children for this DataSnapshot.
     * @return {number} The number of children that this DataSnapshot contains.
     */
    DataSnapshot.prototype.numChildren = function () {
        util_1.validateArgCount('DataSnapshot.numChildren', 0, 0, arguments.length);
        return this.node_.numChildren();
    };
    /**
     * @return {Reference} The Firebase reference for the location this snapshot's data came from.
     */
    DataSnapshot.prototype.getRef = function () {
        util_1.validateArgCount('DataSnapshot.ref', 0, 0, arguments.length);
        return this.ref_;
    };
    Object.defineProperty(DataSnapshot.prototype, "ref", {
        get: function () {
            return this.getRef();
        },
        enumerable: true,
        configurable: true
    });
    return DataSnapshot;
}());
exports.DataSnapshot = DataSnapshot;

//# sourceMappingURL=DataSnapshot.js.map
