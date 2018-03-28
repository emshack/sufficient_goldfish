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
var credential_1 = require("../auth/credential");
var validator = require("../utils/validator");
var utils = require("../utils/index");
/**
 * Internals of a Firestore instance.
 */
var FirestoreInternals = /** @class */ (function () {
    function FirestoreInternals() {
    }
    /**
     * Deletes the service and its associated resources.
     *
     * @return {Promise<()>} An empty Promise that will be fulfilled when the service is deleted.
     */
    FirestoreInternals.prototype.delete = function () {
        // There are no resources to clean up.
        return Promise.resolve();
    };
    return FirestoreInternals;
}());
var FirestoreService = /** @class */ (function () {
    function FirestoreService(app) {
        this.INTERNAL = new FirestoreInternals();
        this.firestoreClient = initFirestore(app);
        this.appInternal = app;
    }
    Object.defineProperty(FirestoreService.prototype, "app", {
        /**
         * Returns the app associated with this Storage instance.
         *
         * @return {FirebaseApp} The app associated with this Storage instance.
         */
        get: function () {
            return this.appInternal;
        },
        enumerable: true,
        configurable: true
    });
    Object.defineProperty(FirestoreService.prototype, "client", {
        get: function () {
            return this.firestoreClient;
        },
        enumerable: true,
        configurable: true
    });
    return FirestoreService;
}());
exports.FirestoreService = FirestoreService;
function initFirestore(app) {
    if (!validator.isNonNullObject(app) || !('options' in app)) {
        throw new error_1.FirebaseFirestoreError({
            code: 'invalid-argument',
            message: 'First argument passed to admin.firestore() must be a valid Firebase app instance.',
        });
    }
    var projectId = utils.getProjectId(app);
    var cert = app.options.credential.getCertificate();
    var options;
    if (cert != null) {
        // cert is available when the SDK has been initialized with a service account JSON file,
        // or by setting the GOOGLE_APPLICATION_CREDENTIALS envrionment variable.
        if (!validator.isNonEmptyString(projectId)) {
            // Assert for an explicit projct ID (either via AppOptions or the cert itself).
            throw new error_1.FirebaseFirestoreError({
                code: 'no-project-id',
                message: 'Failed to determine project ID for Firestore. Initialize the '
                    + 'SDK with service account credentials or set project ID as an app option. '
                    + 'Alternatively set the GCLOUD_PROJECT environment variable.',
            });
        }
        options = {
            credentials: {
                private_key: cert.privateKey,
                client_email: cert.clientEmail,
            },
            projectId: projectId,
        };
    }
    else if (app.options.credential instanceof credential_1.ApplicationDefaultCredential) {
        // Try to use the Google application default credentials.
        // If an explicit project ID is not available, let Firestore client discover one from the
        // environment. This prevents the users from having to set GCLOUD_PROJECT in GCP runtimes.
        options = validator.isNonEmptyString(projectId) ? { projectId: projectId } : {};
    }
    else {
        throw new error_1.FirebaseFirestoreError({
            code: 'invalid-credential',
            message: 'Failed to initialize Google Cloud Firestore client with the available credentials. ' +
                'Must initialize the SDK with a certificate credential or application default credentials ' +
                'to use Cloud Firestore API.',
        });
    }
    // Lazy-load the Firestore implementation here, which in turns loads gRPC.
    var firestoreDatabase = require('@google-cloud/firestore');
    return new firestoreDatabase(options);
}
