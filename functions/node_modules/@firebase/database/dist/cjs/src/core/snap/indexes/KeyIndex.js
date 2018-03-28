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
var Node_1 = require("../Node");
var util_1 = require("../../util/util");
var util_2 = require("@firebase/util");
var __EMPTY_NODE;
var KeyIndex = /** @class */ (function (_super) {
    tslib_1.__extends(KeyIndex, _super);
    function KeyIndex() {
        return _super !== null && _super.apply(this, arguments) || this;
    }
    Object.defineProperty(KeyIndex, "__EMPTY_NODE", {
        get: function () {
            return __EMPTY_NODE;
        },
        set: function (val) {
            __EMPTY_NODE = val;
        },
        enumerable: true,
        configurable: true
    });
    /**
     * @inheritDoc
     */
    KeyIndex.prototype.compare = function (a, b) {
        return util_1.nameCompare(a.name, b.name);
    };
    /**
     * @inheritDoc
     */
    KeyIndex.prototype.isDefinedOn = function (node) {
        // We could probably return true here (since every node has a key), but it's never called
        // so just leaving unimplemented for now.
        throw util_2.assertionError('KeyIndex.isDefinedOn not expected to be called.');
    };
    /**
     * @inheritDoc
     */
    KeyIndex.prototype.indexedValueChanged = function (oldNode, newNode) {
        return false; // The key for a node never changes.
    };
    /**
     * @inheritDoc
     */
    KeyIndex.prototype.minPost = function () {
        return Node_1.NamedNode.MIN;
    };
    /**
     * @inheritDoc
     */
    KeyIndex.prototype.maxPost = function () {
        // TODO: This should really be created once and cached in a static property, but
        // NamedNode isn't defined yet, so I can't use it in a static.  Bleh.
        return new Node_1.NamedNode(util_1.MAX_NAME, __EMPTY_NODE);
    };
    /**
     * @param {*} indexValue
     * @param {string} name
     * @return {!NamedNode}
     */
    KeyIndex.prototype.makePost = function (indexValue, name) {
        util_2.assert(typeof indexValue === 'string', 'KeyIndex indexValue must always be a string.');
        // We just use empty node, but it'll never be compared, since our comparator only looks at name.
        return new Node_1.NamedNode(indexValue, __EMPTY_NODE);
    };
    /**
     * @return {!string} String representation for inclusion in a query spec
     */
    KeyIndex.prototype.toString = function () {
        return '.key';
    };
    return KeyIndex;
}(Index_1.Index));
exports.KeyIndex = KeyIndex;
exports.KEY_INDEX = new KeyIndex();

//# sourceMappingURL=KeyIndex.js.map
