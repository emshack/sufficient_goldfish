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
var logger_1 = require("./src/logger");
function setLogLevel(level) {
    logger_1.instances.forEach(function (inst) {
        inst.logLevel = level;
    });
}
exports.setLogLevel = setLogLevel;
var logger_2 = require("./src/logger");
exports.Logger = logger_2.Logger;
exports.LogLevel = logger_2.LogLevel;

//# sourceMappingURL=index.js.map
