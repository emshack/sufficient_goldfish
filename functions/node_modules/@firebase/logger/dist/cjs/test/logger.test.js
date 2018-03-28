"use strict";
/**
 * Copyright 2018 Google Inc.
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
var chai_1 = require("chai");
var sinon_1 = require("sinon");
var logger_1 = require("../src/logger");
var index_1 = require("../index");
describe('@firebase/logger', function () {
    var message = 'Hello there!';
    var client;
    var spies = {
        logSpy: null,
        infoSpy: null,
        warnSpy: null,
        errorSpy: null
    };
    /**
     * Before each test, instantiate a new instance of Logger and establish spies
     * on all of the console methods so we can assert against them as needed
     */
    beforeEach(function () {
        client = new logger_1.Logger('@firebase/test-logger');
        spies.logSpy = sinon_1.spy(console, 'log');
        spies.infoSpy = sinon_1.spy(console, 'info');
        spies.warnSpy = sinon_1.spy(console, 'warn');
        spies.errorSpy = sinon_1.spy(console, 'error');
    });
    afterEach(function () {
        spies.logSpy.restore();
        spies.infoSpy.restore();
        spies.warnSpy.restore();
        spies.errorSpy.restore();
    });
    function testLog(message, channel, shouldLog) {
        /**
         * Ensure that `debug` logs assert against the `console.log` function. The
         * rationale here is explained in `logger.ts`.
         */
        channel = channel === 'debug' ? 'log' : channel;
        it("Should " + (shouldLog ? '' : 'not') + " call `console." + channel + "` if `." + channel + "` is called", function () {
            client[channel](message);
            chai_1.expect(spies[channel + "Spy"] && spies[channel + "Spy"].called, "Expected " + channel + " to " + (shouldLog ? '' : 'not') + " log").to.be[shouldLog ? 'true' : 'false'];
        });
    }
    describe('Class instance methods', function () {
        beforeEach(function () {
            index_1.setLogLevel(logger_1.LogLevel.DEBUG);
        });
        testLog(message, 'debug', true);
        testLog(message, 'log', true);
        testLog(message, 'info', true);
        testLog(message, 'warn', true);
        testLog(message, 'error', true);
    });
    describe('Defaults to LogLevel.NOTICE', function () {
        testLog(message, 'debug', false);
        testLog(message, 'log', false);
        testLog(message, 'info', true);
        testLog(message, 'warn', true);
        testLog(message, 'error', true);
    });
    describe("Doesn't log if LogLevel.SILENT is set", function () {
        beforeEach(function () {
            index_1.setLogLevel(logger_1.LogLevel.SILENT);
        });
        testLog(message, 'debug', false);
        testLog(message, 'log', false);
        testLog(message, 'info', false);
        testLog(message, 'warn', false);
        testLog(message, 'error', false);
    });
});

//# sourceMappingURL=logger.test.js.map
