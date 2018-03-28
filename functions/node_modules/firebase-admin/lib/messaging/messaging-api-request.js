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
var api_request_1 = require("../utils/api-request");
var error_1 = require("../utils/error");
var validator = require("../utils/validator");
// FCM backend constants
var FIREBASE_MESSAGING_PORT = 443;
var FIREBASE_MESSAGING_TIMEOUT = 10000;
var FIREBASE_MESSAGING_HTTP_METHOD = 'POST';
var FIREBASE_MESSAGING_HEADERS = {
    'Content-Type': 'application/json',
    'Sdk-Version': 'Node/Admin/5.10.0',
    'access_token_auth': 'true',
};
/**
 * Class that provides a mechanism to send requests to the Firebase Cloud Messaging backend.
 */
var FirebaseMessagingRequestHandler = /** @class */ (function () {
    /**
     * @param {FirebaseApp} app The app used to fetch access tokens to sign API requests.
     * @constructor
     */
    function FirebaseMessagingRequestHandler(app) {
        this.signedApiRequestHandler = new api_request_1.SignedApiRequestHandler(app);
    }
    /**
     * @param {object} response The response to check for errors.
     * @return {string|null} The error code if present; null otherwise.
     */
    FirebaseMessagingRequestHandler.getErrorCode = function (response) {
        if (validator.isNonNullObject(response) && 'error' in response) {
            if (typeof response.error === 'string') {
                return response.error;
            }
            else if ('status' in response.error) {
                return response.error.status;
            }
            else {
                return response.error.message;
            }
        }
        return null;
    };
    /**
     * Extracts error message from the given response object.
     *
     * @param {object} response The response to check for errors.
     * @return {string|null} The error message if present; null otherwise.
     */
    FirebaseMessagingRequestHandler.getErrorMessage = function (response) {
        if (validator.isNonNullObject(response) &&
            'error' in response &&
            validator.isNonEmptyString(response.error.message)) {
            return response.error.message;
        }
        return null;
    };
    /**
     * Invokes the request handler with the provided request data.
     *
     * @param {string} host The host to which to send the request.
     * @param {string} path The path to which to send the request.
     * @param {object} requestData The request data.
     * @return {Promise<object>} A promise that resolves with the response.
     */
    FirebaseMessagingRequestHandler.prototype.invokeRequestHandler = function (host, path, requestData) {
        return this.signedApiRequestHandler.sendRequest(host, FIREBASE_MESSAGING_PORT, path, FIREBASE_MESSAGING_HTTP_METHOD, requestData, FIREBASE_MESSAGING_HEADERS, FIREBASE_MESSAGING_TIMEOUT).then(function (response) {
            // Send non-JSON responses to the catch() below where they will be treated as errors.
            if (typeof response === 'string') {
                return Promise.reject({
                    error: response,
                    statusCode: 200,
                });
            }
            // Check for backend errors in the response.
            var errorCode = FirebaseMessagingRequestHandler.getErrorCode(response);
            if (errorCode) {
                return Promise.reject({
                    error: response,
                    statusCode: 200,
                });
            }
            // Return entire response.
            return response;
        })
            .catch(function (response) {
            // Re-throw the error if it already has the proper format.
            if (response instanceof error_1.FirebaseError) {
                throw response;
            }
            else if (response.error instanceof error_1.FirebaseError) {
                throw response.error;
            }
            // Add special handling for non-JSON responses.
            if (typeof response.error === 'string') {
                var error = void 0;
                switch (response.statusCode) {
                    case 400:
                        error = error_1.MessagingClientErrorCode.INVALID_ARGUMENT;
                        break;
                    case 401:
                    case 403:
                        error = error_1.MessagingClientErrorCode.AUTHENTICATION_ERROR;
                        break;
                    case 500:
                        error = error_1.MessagingClientErrorCode.INTERNAL_ERROR;
                        break;
                    case 503:
                        error = error_1.MessagingClientErrorCode.SERVER_UNAVAILABLE;
                        break;
                    default:
                        // Treat non-JSON responses with unexpected status codes as unknown errors.
                        error = error_1.MessagingClientErrorCode.UNKNOWN_ERROR;
                }
                throw new error_1.FirebaseMessagingError({
                    code: error.code,
                    message: error.message + " Raw server response: \"" + response.error + "\". Status code: " +
                        (response.statusCode + "."),
                });
            }
            // For JSON responses, map the server response to a client-side error.
            var errorCode = FirebaseMessagingRequestHandler.getErrorCode(response.error);
            var errorMessage = FirebaseMessagingRequestHandler.getErrorMessage(response.error);
            throw error_1.FirebaseMessagingError.fromServerError(errorCode, errorMessage, response.error);
        });
    };
    return FirebaseMessagingRequestHandler;
}());
exports.FirebaseMessagingRequestHandler = FirebaseMessagingRequestHandler;
