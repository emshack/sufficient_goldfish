/*! firebase-admin v5.10.0 */
"use strict";
/*!
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
var error_1 = require("../utils/error");
var api_request_1 = require("../utils/api-request");
var validator = require("../utils/validator");
/** Firebase IID backend host. */
var FIREBASE_IID_HOST = 'console.firebase.google.com';
/** Firebase IID backend port number. */
var FIREBASE_IID_PORT = 443;
/** Firebase IID backend path. */
var FIREBASE_IID_PATH = '/v1/';
/** Firebase IID request timeout duration in milliseconds. */
var FIREBASE_IID_TIMEOUT = 10000;
/** HTTP error codes raised by the backend server. */
var ERROR_CODES = {
    400: 'Malformed instance ID argument.',
    401: 'Request not authorized.',
    403: 'Project does not match instance ID or the client does not have sufficient privileges.',
    404: 'Failed to find the instance ID.',
    409: 'Already deleted.',
    429: 'Request throttled out by the backend server.',
    500: 'Internal server error.',
    503: 'Backend servers are over capacity. Try again later.',
};
/**
 * Class that provides mechanism to send requests to the Firebase Instance ID backend endpoints.
 */
var FirebaseInstanceIdRequestHandler = /** @class */ (function () {
    /**
     * @param {FirebaseApp} app The app used to fetch access tokens to sign API requests.
     * @param {string} projectId A Firebase project ID string.
     *
     * @constructor
     */
    function FirebaseInstanceIdRequestHandler(app, projectId) {
        this.host = FIREBASE_IID_HOST;
        this.port = FIREBASE_IID_PORT;
        this.timeout = FIREBASE_IID_TIMEOUT;
        this.signedApiRequestHandler = new api_request_1.SignedApiRequestHandler(app);
        this.path = FIREBASE_IID_PATH + ("project/" + projectId + "/instanceId/");
    }
    FirebaseInstanceIdRequestHandler.prototype.deleteInstanceId = function (instanceId) {
        if (!validator.isNonEmptyString(instanceId)) {
            return Promise.reject(new error_1.FirebaseInstanceIdError(error_1.InstanceIdClientErrorCode.INVALID_INSTANCE_ID, 'Instance ID must be a non-empty string.'));
        }
        return this.invokeRequestHandler(new api_request_1.ApiSettings(instanceId, 'DELETE'));
    };
    /**
     * Invokes the request handler based on the API settings object passed.
     *
     * @param {ApiSettings} apiSettings The API endpoint settings to apply to request and response.
     * @return {Promise<object>} A promise that resolves with the response.
     */
    FirebaseInstanceIdRequestHandler.prototype.invokeRequestHandler = function (apiSettings) {
        var _this = this;
        var path = this.path + apiSettings.getEndpoint();
        var httpMethod = apiSettings.getHttpMethod();
        return Promise.resolve()
            .then(function () {
            return _this.signedApiRequestHandler.sendRequest(_this.host, _this.port, path, httpMethod, undefined, undefined, _this.timeout);
        })
            .then(function (response) {
            return response;
        })
            .catch(function (response) {
            var error = (typeof response === 'object' && 'error' in response) ?
                response.error : response;
            if (error instanceof error_1.FirebaseError) {
                // In case of timeouts and other network errors, the API request handler returns a
                // FirebaseError wrapped in the response. Simply throw it here.
                throw error;
            }
            var template = ERROR_CODES[response.statusCode];
            var message = template ?
                "Instance ID \"" + apiSettings.getEndpoint() + "\": " + template : JSON.stringify(error);
            throw new error_1.FirebaseInstanceIdError(error_1.InstanceIdClientErrorCode.API_ERROR, message);
        });
    };
    return FirebaseInstanceIdRequestHandler;
}());
exports.FirebaseInstanceIdRequestHandler = FirebaseInstanceIdRequestHandler;
