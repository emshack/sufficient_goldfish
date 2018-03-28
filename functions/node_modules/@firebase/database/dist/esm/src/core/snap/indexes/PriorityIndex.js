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
import * as tslib_1 from "tslib";
import { Index } from './Index';
import { nameCompare, MAX_NAME } from '../../util/util';
import { NamedNode } from '../Node';
import { LeafNode } from '../LeafNode';
var nodeFromJSON;
var MAX_NODE;
export function setNodeFromJSON(val) {
    nodeFromJSON = val;
}
export function setMaxNode(val) {
    MAX_NODE = val;
}
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
            return nameCompare(a.name, b.name);
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
        return NamedNode.MIN;
    };
    /**
     * @inheritDoc
     */
    PriorityIndex.prototype.maxPost = function () {
        return new NamedNode(MAX_NAME, new LeafNode('[PRIORITY-POST]', MAX_NODE));
    };
    /**
     * @param {*} indexValue
     * @param {string} name
     * @return {!NamedNode}
     */
    PriorityIndex.prototype.makePost = function (indexValue, name) {
        var priorityNode = nodeFromJSON(indexValue);
        return new NamedNode(name, new LeafNode('[PRIORITY-POST]', priorityNode));
    };
    /**
     * @return {!string} String representation for inclusion in a query spec
     */
    PriorityIndex.prototype.toString = function () {
        return '.priority';
    };
    return PriorityIndex;
}(Index));
export { PriorityIndex };
export var PRIORITY_INDEX = new PriorityIndex();

//# sourceMappingURL=PriorityIndex.js.map
