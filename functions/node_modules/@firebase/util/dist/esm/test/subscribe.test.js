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
import { assert } from 'chai';
import * as sinon from 'sinon';
import { async, createSubscribe } from '../src/subscribe';
describe('createSubscribe', function () {
    var spy;
    beforeEach(function () {
        // Listen to console.error calls.
        spy = sinon.spy(console, 'error');
    });
    afterEach(function () {
        spy.restore();
    });
    it('Creation', function (done) {
        var subscribe = createSubscribe(function (observer) {
            observer.next(123);
        });
        var unsub = subscribe(function (value) {
            unsub();
            assert.equal(value, 123);
            done();
        });
    });
    it('Logging observer error to console', function (done) {
        var uncatchableError = new Error('uncatchable');
        var subscribe = createSubscribe(function (observer) {
            observer.next(123);
            observer.complete();
        });
        subscribe({
            next: function (value) {
                assert.equal(value, 123);
                // Simulate an error is thrown in the next callback.
                // This should log to the console as an error.
                throw uncatchableError;
            },
            complete: function () {
                // By this point, the error should have been logged.
                assert.ok(spy.calledWith(uncatchableError));
                done();
            }
        });
    });
    it('Well-defined subscription order', function (done) {
        var subscribe = createSubscribe(function (observer) {
            observer.next(123);
            // Subscription after value emitted should NOT be received.
            subscribe({
                next: function (value) {
                    assert.ok(false);
                }
            });
        });
        // Subscription before value emitted should be recieved.
        subscribe({
            next: function (value) {
                done();
            }
        });
    });
    it('Subscribing to already complete Subscribe', function (done) {
        var seq = 0;
        var subscribe = createSubscribe(function (observer) {
            observer.next(456);
            observer.complete();
        });
        subscribe({
            next: function (value) {
                assert.equal(seq++, 0);
                assert.equal(value, 456);
            },
            complete: function () {
                subscribe({
                    complete: function () {
                        assert.equal(seq++, 1);
                        done();
                    }
                });
            }
        });
    });
    it('Subscribing to errored Subscribe', function (done) {
        var seq = 0;
        var subscribe = createSubscribe(function (observer) {
            observer.next(246);
            observer.error(new Error('failure'));
        });
        subscribe({
            next: function (value) {
                assert.equal(seq++, 0);
                assert.equal(value, 246);
            },
            error: function (e) {
                assert.equal(seq++, 1);
                subscribe({
                    error: function (e2) {
                        assert.equal(seq++, 2);
                        assert.equal(e.message, 'failure');
                        done();
                    }
                });
            },
            complete: function () {
                assert.ok(false);
            }
        });
    });
    it('Delayed value', function (done) {
        var subscribe = createSubscribe(function (observer) {
            setTimeout(function () { return observer.next(123); }, 10);
        });
        subscribe(function (value) {
            assert.equal(value, 123);
            done();
        });
    });
    it('Executor throws => Error', function () {
        // It's an application error to throw an exception in the executor -
        // but since it is called asynchronously, our only option is
        // to emit that Error and terminate the Subscribe.
        var subscribe = createSubscribe(function (observer) {
            throw new Error('Executor throws');
        });
        subscribe({
            error: function (e) {
                assert.equal(e.message, 'Executor throws');
            }
        });
    });
    it('Sequence', function (done) {
        var subscribe = makeCounter(10);
        var j = 1;
        subscribe({
            next: function (value) {
                assert.equal(value, j++);
            },
            complete: function () {
                assert.equal(j, 11);
                done();
            }
        });
    });
    it('unlisten', function (done) {
        var subscribe = makeCounter(10);
        subscribe({
            complete: function () {
                async(done)();
            }
        });
        var j = 1;
        var unsub = subscribe({
            next: function (value) {
                assert.ok(value <= 5);
                assert.equal(value, j++);
                if (value === 5) {
                    unsub();
                }
            },
            complete: function () {
                assert.ok(false, 'Does not call completed if unsubscribed');
            }
        });
    });
    it('onNoObservers', function (done) {
        var subscribe = makeCounter(10);
        var j = 1;
        var unsub = subscribe({
            next: function (value) {
                assert.ok(value <= 5);
                assert.equal(value, j++);
                if (value === 5) {
                    unsub();
                    async(done)();
                }
            },
            complete: function () {
                assert.ok(false, 'Does not call completed if unsubscribed');
            }
        });
    });
    // TODO(koss): Add test for partial Observer (missing methods).
    it('Partial Observer', function (done) {
        var subscribe = makeCounter(10);
        var unsub = subscribe({
            complete: function () {
                done();
            }
        });
    });
});
function makeCounter(maxCount, ms) {
    if (ms === void 0) { ms = 10; }
    var id;
    return createSubscribe(function (observer) {
        var i = 1;
        id = setInterval(function () {
            observer.next(i++);
            if (i > maxCount) {
                if (id) {
                    clearInterval(id);
                    id = undefined;
                }
                observer.complete();
            }
        }, ms);
    }, function (observer) {
        clearInterval(id);
        id = undefined;
    });
}

//# sourceMappingURL=subscribe.test.js.map
