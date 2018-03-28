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
var Index_1 = require("./Index");
var util_1 = require("../../util/util");
var Node_1 = require("../Node");
var LeafNode_1 = require("../LeafNode");
var nodeFromJSON;
var MAX_NODE;
function setNodeFromJSON(val) {
    nodeFromJSON = val;
}
exports.setNodeFromJSON = setNodeFromJSON;
function setMaxNode(val) {
    MAX_NODE = val;
}
exports.setMaxNode = setMaxNode;
/**
 * @constructor
 * @extends {Index}
 * @private
 */
var PriorityIndex = /** @class */ (function (_super) {
    tslib_1.__extends(PriorityIndex, _super);
    function PriorityIndex() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.compare = function (a, b) {
        var aPriority = a.node.getPriority();
        var bPriority = b.node.getPriority();
        var indexCmp = aPriority.compareTo(bPriority);
        if (indexCmp === 0) {
            return util_1.nameCompare(a.name, b.name);
        }
        else {
            return indexCmp;
        }
    };
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.isDefinedOn = function (node) {
        return !node.getPriority().isEmpty();
    };
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.indexedValueChanged = function (oldNode, newNode) {
        return !oldNode.getPriority().equals(newNode.getPriority());
    };
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.minPost = function () {
        return Node_1.NamedNode.MIN;
    };
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.maxPost = function () {
        return new Node_1.NamedNode(util_1.MAX_NAME, new LeafNode_1.LeafNode('[PRIORITY-POST]', MAX_NODE));
    };
    /**
     * @param {*} indexValue
     * @param {string} name
     * @return {!NamedNode}
     */
    PriorityIndex.prototype.makePost = function (indexValue, name) {
        var priorityNode = nodeFromJSON(indexValue);
        return new Node_1.NamedNode(name, new LeafNode_1.LeafNode('[PRIORITY-POST]', priorityNode));
    };
    /**
     * @return {!string} String representation for inclusion in a query spec
     */
    PriorityIndex.prototype.toString = function () {
        return '.priority';
    };
    return PriorityIndex;
}(Index_1.Index));
exports.PriorityIndex = PriorityIndex;
exports.PRIORITY_INDEX = new PriorityIndex();

//# sourceMappingURL=PriorityIndex.js.map
