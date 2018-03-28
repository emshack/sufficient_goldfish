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
var Path_1 = require("./Path");
var SparseSnapshotTree_1 = require("../SparseSnapshotTree");
var LeafNode_1 = require("../snap/LeafNode");
var nodeFromJSON_1 = require("../snap/nodeFromJSON");
var PriorityIndex_1 = require("../snap/indexes/PriorityIndex");
/**
 * Generate placeholders for deferred values.
 * @param {?Object} values
 * @return {!Object}
 */
exports.generateWithValues = function (values) {
    values = values || {};
    values['timestamp'] = values['timestamp'] || new Date().getTime();
    return values;
};
/**
 * Value to use when firing local events. When writing server values, fire
 * local events with an approximate value, otherwise return value as-is.
 * @param {(Object|string|number|boolean)} value
 * @param {!Object} serverValues
 * @return {!(string|number|boolean)}
 */
exports.resolveDeferredValue = function (value, serverValues) {
    if (!value || typeof value !== 'object') {
        return value;
    }
    else {
        util_1.assert('.sv' in value, 'Unexpected leaf node or priority contents');
        return serverValues[value['.sv']];
    }
};
/**
 * Recursively replace all deferred values and priorities in the tree with the
 * specified generated replacement values.
 * @param {!SparseSnapshotTree} tree
 * @param {!Object} serverValues
 * @return {!SparseSnapshotTree}
 */
exports.resolveDeferredValueTree = function (tree, serverValues) {
    var resolvedTree = new SparseSnapshotTree_1.SparseSnapshotTree();
    tree.forEachTree(new Path_1.Path(''), function (path, node) {
        resolvedTree.remember(path, exports.resolveDeferredValueSnapshot(node, serverValues));
    });
    return resolvedTree;
};
/**
 * Recursively replace all deferred values and priorities in the node with the
 * specified generated replacement values.  If there are no server values in the node,
 * it'll be returned as-is.
 * @param {!Node} node
 * @param {!Object} serverValues
 * @return {!Node}
 */
exports.resolveDeferredValueSnapshot = function (node, serverValues) {
    var rawPri = node.getPriority().val();
    var priority = exports.resolveDeferredValue(rawPri, serverValues);
    var newNode;
    if (node.isLeafNode()) {
        var leafNode = node;
        var value = exports.resolveDeferredValue(leafNode.getValue(), serverValues);
        if (value !== leafNode.getValue() ||
            priority !== leafNode.getPriority().val()) {
            return new LeafNode_1.LeafNode(value, nodeFromJSON_1.nodeFromJSON(priority));
        }
        else {
            return node;
        }
    }
    else {
        var childrenNode = node;
        newNode = childrenNode;
        if (priority !== childrenNode.getPriority().val()) {
            newNode = newNode.updatePriority(new LeafNode_1.LeafNode(priority));
        }
        childrenNode.forEachChild(PriorityIndex_1.PRIORITY_INDEX, function (childName, childNode) {
            var newChildNode = exports.resolveDeferredValueSnapshot(childNode, serverValues);
            if (newChildNode !== childNode) {
                newNode = newNode.updateImmediateChild(childName, newChildNode);
            }
        });
        return newNode;
    }
};

//# sourceMappingURL=ServerValues.js.map
