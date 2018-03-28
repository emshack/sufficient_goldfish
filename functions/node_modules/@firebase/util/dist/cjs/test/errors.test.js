"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
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
var chai_1 = require("chai");
var errors_1 = require("../src/errors");
var errors = {
    'generic-error': 'Unknown error',
    'file-not-found': "Could not find file: '{$file}'",
    'anon-replace': 'Hello, {$repl_}!'
};
var error = new errors_1.ErrorFactory('fake', 'Fake', errors);
describe('FirebaseError', function () {
    it('create', function () {
        var e = error.create('generic-error');
        chai_1.assert.equal(e.code, 'fake/generic-error');
        chai_1.assert.equal(e.message, 'Fake: Unknown error (fake/generic-error).');
    });
    it('String replacement', function () {
        var e = error.create('file-not-found', { file: 'foo.txt' });
        chai_1.assert.equal(e.code, 'fake/file-not-found');
        chai_1.assert.equal(e.message, "Fake: Could not find file: 'foo.txt' (fake/file-not-found).");
        chai_1.assert.equal(e.file, 'foo.txt');
    });
    it('Anonymous String replacement', function () {
        var e = error.create('anon-replace', { repl_: 'world' });
        chai_1.assert.equal(e.code, 'fake/anon-replace');
        chai_1.assert.equal(e.message, 'Fake: Hello, world! (fake/anon-replace).');
        chai_1.assert.isUndefined(e.repl_);
    });
    it('Missing template', function () {
        // Cast to avoid compile-time error.
        var e = error.create('no-such-code');
        chai_1.assert.equal(e.code, 'fake/no-such-code');
        chai_1.assert.equal(e.message, 'Fake: Error (fake/no-such-code).');
    });
    it('Missing replacement', function () {
        var e = error.create('file-not-found', { fileX: 'foo.txt' });
        chai_1.assert.equal(e.code, 'fake/file-not-found');
        chai_1.assert.equal(e.message, "Fake: Could not find file: '<file?>' (fake/file-not-found).");
    });
});
// Run the stack trace tests with, and without, Error.captureStackTrace
var realCapture = errors_1.patchCapture();
stackTests(realCapture);
stackTests(undefined);
function stackTests(fakeCapture) {
    var saveCapture;
    describe('Error#stack tests - Error.captureStackTrace is ' +
        (fakeCapture ? 'defined' : 'NOT defined'), function () {
        before(function () {
            saveCapture = errors_1.patchCapture(fakeCapture);
        });
        after(function () {
            errors_1.patchCapture(saveCapture);
        });
        it('has stack', function () {
            var e = error.create('generic-error');
            // Multi-line match trick - .* does not match \n
            chai_1.assert.match(e.stack, /FirebaseError[\s\S]/);
        });
        it('stack frames', function () {
            try {
                dummy1();
                chai_1.assert.ok(false);
            }
            catch (e) {
                chai_1.assert.match(e.stack, /dummy2[\s\S]*?dummy1/);
            }
        });
    });
}
function dummy1() {
    dummy2();
}
function dummy2() {
    var error = new errors_1.ErrorFactory('dummy', 'Dummy', errors);
    throw error.create('generic-error');
}

//# sourceMappingURL=errors.test.js.map
