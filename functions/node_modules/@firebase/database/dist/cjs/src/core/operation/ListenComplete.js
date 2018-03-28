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
var Path_1 = require("../util/Path");
var Operation_1 = require("./Operation");
/**
 * @param {!OperationSource} source
 * @param {!Path} path
 * @constructor
 * @implements {Operation}
 */
var ListenComplete = /** @class */ (function () {
    function ListenComplete(source, path) {
        this.source = source;
        this.path = path;
        /** @inheritDoc */
        this.type = Operation_1.OperationType.LISTEN_COMPLETE;
    }
    ListenComplete.prototype.operationForChild = function (childName) {
        if (this.path.isEmpty()) {
            return new ListenComplete(this.source, Path_1.Path.Empty);
        }
        else {
            return new ListenComplete(this.source, this.path.popFront());
        }
    };
    return ListenComplete;
}());
exports.ListenComplete = ListenComplete;

//# sourceMappingURL=ListenComplete.js.map
