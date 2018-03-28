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
import { assert } from '@firebase/util';
import { nameCompare, MAX_NAME } from '../../util/util';
import { Index } from './Index';
import { ChildrenNode, MAX_NODE } from '../ChildrenNode';
import { NamedNode } from '../Node';
import { nodeFromJSON } from '../nodeFromJSON';
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
        assert(!indexPath_.isEmpty() && indexPath_.getFront() !== '.priority', "Can't create PathIndex with empty path or .priority key");
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
            return nameCompare(a.name, b.name);
        }
        else {
            return indexCmp;
        }
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.makePost = function (indexValue, name) {
        var valueNode = nodeFromJSON(indexValue);
        var node = ChildrenNode.EMPTY_NODE.updateChild(this.indexPath_, valueNode);
        return new NamedNode(name, node);
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.maxPost = function () {
        var node = ChildrenNode.EMPTY_NODE.updateChild(this.indexPath_, MAX_NODE);
        return new NamedNode(MAX_NAME, node);
    };
    /**
     * @inheritDoc
     */
    PathIndex.prototype.toString = function () {
        return this.indexPath_.slice().join('/');
    };
    return PathIndex;
}(Index));
export { PathIndex };

//# sourceMappingURL=PathIndex.js.map
