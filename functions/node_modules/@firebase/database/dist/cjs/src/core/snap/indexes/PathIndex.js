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
var util_1 = require("@firebase/util");
var util_2 = require("../../util/util");
var Index_1 = require("./Index");
var ChildrenNode_1 = require("../ChildrenNode");
var Node_1 = require("../Node");
var nodeFromJSON_1 = require("../nodeFromJSON");
/**
 * @param {!Path} indexPath
 * @constructor
 * @extends {Index}
 */
var PathIndex = /** @class */ (function (_super) {
    tslib_1.__extends(PathIndex, _super);
    function PathIndex(indexPath_) {
        var _this = _super.call(this) || this;
        _this.indexPath_ = indexPath_;
        util_1.assert(!indexPath_.isEmpty() && indexPath_.getFront() !== '.priority', "Can't create PathIndex with empty path or .priority key");
        return _this;
    }
    /**
     * @param {!Node} snap
     * @return {!Node}
     * @protected
     */
    PathIndex.prototype.extractChild = function (snap) {
        return snap.getChild(this.indexPath_);
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.isDefinedOn = function (node) {
        return !node.getChild(this.indexPath_).isEmpty();
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.compare = function (a, b) {
        var aChild = this.extractChild(a.node);
        var bChild = this.extractChild(b.node);
        var indexCmp = aChild.compareTo(bChild);
        if (indexCmp === 0) {
            return util_2.nameCompare(a.name, b.name);
        }
        else {
            return indexCmp;
        }
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.makePost = function (indexValue, name) {
        var valueNode = nodeFromJSON_1.nodeFromJSON(indexValue);
        var node = ChildrenNode_1.ChildrenNode.EMPTY_NODE.updateChild(this.indexPath_, valueNode);
        return new Node_1.NamedNode(name, node);
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.maxPost = function () {
        var node = ChildrenNode_1.ChildrenNode.EMPTY_NODE.updateChild(this.indexPath_, ChildrenNode_1.MAX_NODE);
        return new Node_1.NamedNode(util_2.MAX_NAME, node);
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.toString = function () {
        return this.indexPath_.slice().join('/');
    };
    return PathIndex;
}(Index_1.Index));
exports.PathIndex = PathIndex;

//# sourceMappingURL=PathIndex.js.map
