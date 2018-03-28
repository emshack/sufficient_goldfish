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
import { NamedNode } from '../Node';
import { nameCompare } from '../../util/util';
import { nodeFromJSON } from '../nodeFromJSON';
/**
 * @constructor
 * @extends {Index}
 * @private
 */
var ValueIndex = /** @class */ (function (_super) {
    tslib_1.__extends(ValueIndex, _super);
    function ValueIndex() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    /**
     * @inheritDoc
     */
    ValueIndex.prototype.compare = function (a, b) {
        var indexCmp = a.node.compareTo(b.node);
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
    ValueIndex.prototype.isDefinedOn = function (node) {
        return true;
    };
    /**
     * @inheritDoc
     */
    ValueIndex.prototype.indexedValueChanged = function (oldNode, newNode) {
        return !oldNode.equals(newNode);
    };
    /**
     * @inheritDoc
     */
    ValueIndex.prototype.minPost = function () {
        return NamedNode.MIN;
    };
    /**
     * @inheritDoc
     */
    ValueIndex.prototype.maxPost = function () {
        return NamedNode.MAX;
    };
    /**
     * @param {*} indexValue
     * @param {string} name
     * @return {!NamedNode}
     */
    ValueIndex.prototype.makePost = function (indexValue, name) {
        var valueNode = nodeFromJSON(indexValue);
        return new NamedNode(name, valueNode);
    };
    /**
     * @return {!string} String representation for inclusion in a query spec
     */
    ValueIndex.prototype.toString = function () {
        return '.value';
    };
    return ValueIndex;
}(Index));
export { ValueIndex };
export var VALUE_INDEX = new ValueIndex();

//# sourceMappingURL=ValueIndex.js.map
