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
var assert_1 = require("./src/assert");
exports.assert = assert_1.assert;
exports.assertionError = assert_1.assertionError;
var crypt_1 = require("./src/crypt");
exports.base64 = crypt_1.base64;
exports.base64Decode = crypt_1.base64Decode;
exports.base64Encode = crypt_1.base64Encode;
var constants_1 = require("./src/constants");
exports.CONSTANTS = constants_1.CONSTANTS;
var deepCopy_1 = require("./src/deepCopy");
exports.deepCopy = deepCopy_1.deepCopy;
exports.deepExtend = deepCopy_1.deepExtend;
exports.patchProperty = deepCopy_1.patchProperty;
var deferred_1 = require("./src/deferred");
exports.Deferred = deferred_1.Deferred;
var environment_1 = require("./src/environment");
exports.getUA = environment_1.getUA;
exports.isMobileCordova = environment_1.isMobileCordova;
exports.isNodeSdk = environment_1.isNodeSdk;
exports.isReactNative = environment_1.isReactNative;
var errors_1 = require("./src/errors");
exports.ErrorFactory = errors_1.ErrorFactory;
exports.FirebaseError = errors_1.FirebaseError;
exports.patchCapture = errors_1.patchCapture;
var json_1 = require("./src/json");
exports.jsonEval = json_1.jsonEval;
exports.stringify = json_1.stringify;
var jwt_1 = require("./src/jwt");
exports.decode = jwt_1.decode;
exports.isAdmin = jwt_1.isAdmin;
exports.issuedAtTime = jwt_1.issuedAtTime;
exports.isValidFormat = jwt_1.isValidFormat;
exports.isValidTimestamp = jwt_1.isValidTimestamp;
var obj_1 = require("./src/obj");
exports.clone = obj_1.clone;
exports.contains = obj_1.contains;
exports.every = obj_1.every;
exports.extend = obj_1.extend;
exports.findKey = obj_1.findKey;
exports.findValue = obj_1.findValue;
exports.forEach = obj_1.forEach;
exports.getAnyKey = obj_1.getAnyKey;
exports.getCount = obj_1.getCount;
exports.getValues = obj_1.getValues;
exports.isEmpty = obj_1.isEmpty;
exports.isNonNullObject = obj_1.isNonNullObject;
exports.map = obj_1.map;
exports.safeGet = obj_1.safeGet;
var query_1 = require("./src/query");
exports.querystring = query_1.querystring;
exports.querystringDecode = query_1.querystringDecode;
var sha1_1 = require("./src/sha1");
exports.Sha1 = sha1_1.Sha1;
var subscribe_1 = require("./src/subscribe");
exports.async = subscribe_1.async;
exports.createSubscribe = subscribe_1.createSubscribe;
var validation_1 = require("./src/validation");
exports.errorPrefix = validation_1.errorPrefix;
exports.validateArgCount = validation_1.validateArgCount;
exports.validateCallback = validation_1.validateCallback;
exports.validateContextObject = validation_1.validateContextObject;
exports.validateNamespace = validation_1.validateNamespace;
var utf8_1 = require("./src/utf8");
exports.stringLength = utf8_1.stringLength;
exports.stringToByteArray = utf8_1.stringToByteArray;

//# sourceMappingURL=index.js.map
