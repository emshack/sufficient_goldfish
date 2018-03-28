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
var Path_1 = require("./Path");
var util_1 = require("@firebase/util");
var util_2 = require("./util");
var util_3 = require("@firebase/util");
var util_4 = require("@firebase/util");
/**
 * True for invalid Firebase keys
 * @type {RegExp}
 * @private
 */
exports.INVALID_KEY_REGEX_ = /[\[\].#$\/\u0000-\u001F\u007F]/;
/**
 * True for invalid Firebase paths.
 * Allows '/' in paths.
 * @type {RegExp}
 * @private
 */
exports.INVALID_PATH_REGEX_ = /[\[\].#$\u0000-\u001F\u007F]/;
/**
 * Maximum number of characters to allow in leaf value
 * @type {number}
 * @private
 */
exports.MAX_LEAF_SIZE_ = 10 * 1024 * 1024;
/**
 * @param {*} key
 * @return {boolean}
 */
exports.isValidKey = function (key) {
    return (typeof key === 'string' && key.length !== 0 && !exports.INVALID_KEY_REGEX_.test(key));
};
/**
 * @param {string} pathString
 * @return {boolean}
 */
exports.isValidPathString = function (pathString) {
    return (typeof pathString === 'string' &&
        pathString.length !== 0 &&
        !exports.INVALID_PATH_REGEX_.test(pathString));
};
/**
 * @param {string} pathString
 * @return {boolean}
 */
exports.isValidRootPathString = function (pathString) {
    if (pathString) {
        // Allow '/.info/' at the beginning.
        pathString = pathString.replace(/^\/*\.info(\/|$)/, '/');
    }
    return exports.isValidPathString(pathString);
};
/**
 * @param {*} priority
 * @return {boolean}
 */
exports.isValidPriority = function (priority) {
    return (priority === null ||
        typeof priority === 'string' ||
        (typeof priority === 'number' && !util_2.isInvalidJSONNumber(priority)) ||
        (priority && typeof priority === 'object' && util_1.contains(priority, '.sv')));
};
/**
 * Pre-validate a datum passed as an argument to Firebase function.
 *
 * @param {string} fnName
 * @param {number} argumentNumber
 * @param {*} data
 * @param {!Path} path
 * @param {boolean} optional
 */
exports.validateFirebaseDataArg = function (fnName, argumentNumber, data, path, optional) {
    if (optional && data === undefined)
        return;
    exports.validateFirebaseData(util_3.errorPrefix(fnName, argumentNumber, optional), data, path);
};
/**
 * Validate a data object client-side before sending to server.
 *
 * @param {string} errorPrefix
 * @param {*} data
 * @param {!Path|!ValidationPath} path_
 */
exports.validateFirebaseData = function (errorPrefix, data, path_) {
    var path = path_ instanceof Path_1.Path ? new Path_1.ValidationPath(path_, errorPrefix) : path_;
    if (data === undefined) {
        throw new Error(errorPrefix + 'contains undefined ' + path.toErrorString());
    }
    if (typeof data === 'function') {
        throw new Error(errorPrefix +
            'contains a function ' +
            path.toErrorString() +
            ' with contents = ' +
            data.toString());
    }
    if (util_2.isInvalidJSONNumber(data)) {
        throw new Error(errorPrefix + 'contains ' + data.toString() + ' ' + path.toErrorString());
    }
    // Check max leaf size, but try to avoid the utf8 conversion if we can.
    if (typeof data === 'string' &&
        data.length > exports.MAX_LEAF_SIZE_ / 3 &&
        util_4.stringLength(data) > exports.MAX_LEAF_SIZE_) {
        throw new Error(errorPrefix +
            'contains a string greater than ' +
            exports.MAX_LEAF_SIZE_ +
            ' utf8 bytes ' +
            path.toErrorString() +
            " ('" +
            data.substring(0, 50) +
            "...')");
    }
    // TODO = Perf = Consider combining the recursive validation of keys into NodeFromJSON
    // to save extra walking of large objects.
    if (data && typeof data === 'object') {
        var hasDotValue_1 = false, hasActualChild_1 = false;
        util_1.forEach(data, function (key, value) {
            if (key === '.value') {
                hasDotValue_1 = true;
            }
            else if (key !== '.priority' && key !== '.sv') {
                hasActualChild_1 = true;
                if (!exports.isValidKey(key)) {
                    throw new Error(errorPrefix +
                        ' contains an invalid key (' +
                        key +
                        ') ' +
                        path.toErrorString() +
                        '.  Keys must be non-empty strings ' +
                        'and can\'t contain ".", "#", "$", "/", "[", or "]"');
                }
            }
            path.push(key);
            exports.validateFirebaseData(errorPrefix, value, path);
            path.pop();
        });
        if (hasDotValue_1 && hasActualChild_1) {
            throw new Error(errorPrefix +
                ' contains ".value" child ' +
                path.toErrorString() +
                ' in addition to actual children.');
        }
    }
};
/**
 * Pre-validate paths passed in the firebase function.
 *
 * @param {string} errorPrefix
 * @param {Array<!Path>} mergePaths
 */
exports.validateFirebaseMergePaths = function (errorPrefix, mergePaths) {
    var i, curPath;
    for (i = 0; i < mergePaths.length; i++) {
        curPath = mergePaths[i];
        var keys = curPath.slice();
        for (var j = 0; j < keys.length; j++) {
            if (keys[j] === '.priority' && j === keys.length - 1) {
                // .priority is OK
            }
            else if (!exports.isValidKey(keys[j])) {
                throw new Error(errorPrefix +
                    'contains an invalid key (' +
                    keys[j] +
                    ') in path ' +
                    curPath.toString() +
                    '. Keys must be non-empty strings ' +
                    'and can\'t contain ".", "#", "$", "/", "[", or "]"');
            }
        }
    }
    // Check that update keys are not descendants of each other.
    // We rely on the property that sorting guarantees that ancestors come
    // right before descendants.
    mergePaths.sort(Path_1.Path.comparePaths);
    var prevPath = null;
    for (i = 0; i < mergePaths.length; i++) {
        curPath = mergePaths[i];
        if (prevPath !== null && prevPath.contains(curPath)) {
            throw new Error(errorPrefix +
                'contains a path ' +
                prevPath.toString() +
                ' that is ancestor of another path ' +
                curPath.toString());
        }
        prevPath = curPath;
    }
};
/**
 * pre-validate an object passed as an argument to firebase function (
 * must be an object - e.g. for firebase.update()).
 *
 * @param {string} fnName
 * @param {number} argumentNumber
 * @param {*} data
 * @param {!Path} path
 * @param {boolean} optional
 */
exports.validateFirebaseMergeDataArg = function (fnName, argumentNumber, data, path, optional) {
    if (optional && data === undefined)
        return;
    var errorPrefix = util_3.errorPrefix(fnName, argumentNumber, optional);
    if (!(data && typeof data === 'object') || Array.isArray(data)) {
        throw new Error(errorPrefix + ' must be an object containing the children to replace.');
    }
    var mergePaths = [];
    util_1.forEach(data, function (key, value) {
        var curPath = new Path_1.Path(key);
        exports.validateFirebaseData(errorPrefix, value, path.child(curPath));
        if (curPath.getBack() === '.priority') {
            if (!exports.isValidPriority(value)) {
                throw new Error(errorPrefix +
                    "contains an invalid value for '" +
                    curPath.toString() +
                    "', which must be a valid " +
                    'Firebase priority (a string, finite number, server value, or null).');
            }
        }
        mergePaths.push(curPath);
    });
    exports.validateFirebaseMergePaths(errorPrefix, mergePaths);
};
exports.validatePriority = function (fnName, argumentNumber, priority, optional) {
    if (optional && priority === undefined)
        return;
    if (util_2.isInvalidJSONNumber(priority))
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'is ' +
            priority.toString() +
            ', but must be a valid Firebase priority (a string, finite number, ' +
            'server value, or null).');
    // Special case to allow importing data with a .sv.
    if (!exports.isValidPriority(priority))
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'must be a valid Firebase priority ' +
            '(a string, finite number, server value, or null).');
};
exports.validateEventType = function (fnName, argumentNumber, eventType, optional) {
    if (optional && eventType === undefined)
        return;
    switch (eventType) {
        case 'value':
        case 'child_added':
        case 'child_removed':
        case 'child_changed':
        case 'child_moved':
            break;
        default:
            throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
                'must be a valid event type = "value", "child_added", "child_removed", ' +
                '"child_changed", or "child_moved".');
    }
};
exports.validateKey = function (fnName, argumentNumber, key, optional) {
    if (optional && key === undefined)
        return;
    if (!exports.isValidKey(key))
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'was an invalid key = "' +
            key +
            '".  Firebase keys must be non-empty strings and ' +
            'can\'t contain ".", "#", "$", "/", "[", or "]").');
};
exports.validatePathString = function (fnName, argumentNumber, pathString, optional) {
    if (optional && pathString === undefined)
        return;
    if (!exports.isValidPathString(pathString))
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'was an invalid path = "' +
            pathString +
            '". Paths must be non-empty strings and ' +
            'can\'t contain ".", "#", "$", "[", or "]"');
};
exports.validateRootPathString = function (fnName, argumentNumber, pathString, optional) {
    if (pathString) {
        // Allow '/.info/' at the beginning.
        pathString = pathString.replace(/^\/*\.info(\/|$)/, '/');
    }
    exports.validatePathString(fnName, argumentNumber, pathString, optional);
};
exports.validateWritablePath = function (fnName, path) {
    if (path.getFront() === '.info') {
        throw new Error(fnName + " failed = Can't modify data under /.info/");
    }
};
exports.validateUrl = function (fnName, argumentNumber, parsedUrl) {
    // TODO = Validate server better.
    var pathString = parsedUrl.path.toString();
    if (!(typeof parsedUrl.repoInfo.host === 'string') ||
        parsedUrl.repoInfo.host.length === 0 ||
        (!exports.isValidKey(parsedUrl.repoInfo.namespace) &&
            parsedUrl.repoInfo.host.split(':')[0] !== 'localhost') ||
        (pathString.length !== 0 && !exports.isValidRootPathString(pathString))) {
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, false) +
            'must be a valid firebase URL and ' +
            'the path can\'t contain ".", "#", "$", "[", or "]".');
    }
};
exports.validateCredential = function (fnName, argumentNumber, cred, optional) {
    if (optional && cred === undefined)
        return;
    if (!(typeof cred === 'string'))
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'must be a valid credential (a string).');
};
exports.validateBoolean = function (fnName, argumentNumber, bool, optional) {
    if (optional && bool === undefined)
        return;
    if (typeof bool !== 'boolean')
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) + 'must be a boolean.');
};
exports.validateString = function (fnName, argumentNumber, string, optional) {
    if (optional && string === undefined)
        return;
    if (!(typeof string === 'string')) {
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'must be a valid string.');
    }
};
exports.validateObject = function (fnName, argumentNumber, obj, optional) {
    if (optional && obj === undefined)
        return;
    if (!(obj && typeof obj === 'object') || obj === null) {
        throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
            'must be a valid object.');
    }
};
exports.validateObjectContainsKey = function (fnName, argumentNumber, obj, key, optional, opt_type) {
    var objectContainsKey = obj && typeof obj === 'object' && util_1.contains(obj, key);
    if (!objectContainsKey) {
        if (optional) {
            return;
        }
        else {
            throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
                'must contain the key "' +
                key +
                '"');
        }
    }
    if (opt_type) {
        var val = util_1.safeGet(obj, key);
        if ((opt_type === 'number' && !(typeof val === 'number')) ||
            (opt_type === 'string' && !(typeof val === 'string')) ||
            (opt_type === 'boolean' && !(typeof val === 'boolean')) ||
            (opt_type === 'function' && !(typeof val === 'function')) ||
            (opt_type === 'object' && !(typeof val === 'object') && val)) {
            if (optional) {
                throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
                    'contains invalid value for key "' +
                    key +
                    '" (must be of type "' +
                    opt_type +
                    '")');
            }
            else {
                throw new Error(util_3.errorPrefix(fnName, argumentNumber, optional) +
                    'must contain the key "' +
                    key +
                    '" with type "' +
                    opt_type +
                    '"');
            }
        }
    }
};

//# sourceMappingURL=validation.js.map
