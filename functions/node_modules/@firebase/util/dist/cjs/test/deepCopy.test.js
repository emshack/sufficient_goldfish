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
var deepCopy_1 = require("../src/deepCopy");
describe('deepCopy()', function () {
    it('Scalars', function () {
        chai_1.assert.strictEqual(deepCopy_1.deepCopy(true), true);
        chai_1.assert.strictEqual(deepCopy_1.deepCopy(123), 123);
        chai_1.assert.strictEqual(deepCopy_1.deepCopy('abc'), 'abc');
    });
    it('Date', function () {
        var d = new Date();
        chai_1.assert.deepEqual(deepCopy_1.deepCopy(d), d);
    });
    it('Object', function () {
        chai_1.assert.deepEqual(deepCopy_1.deepCopy({}), {});
        chai_1.assert.deepEqual(deepCopy_1.deepCopy({ a: 123 }), { a: 123 });
        chai_1.assert.deepEqual(deepCopy_1.deepCopy({ a: { b: 123 } }), { a: { b: 123 } });
    });
    it('Array', function () {
        chai_1.assert.deepEqual(deepCopy_1.deepCopy([]), []);
        chai_1.assert.deepEqual(deepCopy_1.deepCopy([123, 456]), [123, 456]);
        chai_1.assert.deepEqual(deepCopy_1.deepCopy([123, [456]]), [123, [456]]);
    });
});
describe('deepExtend', function () {
    it('Scalars', function () {
        chai_1.assert.strictEqual(deepCopy_1.deepExtend(1, true), true);
        chai_1.assert.strictEqual(deepCopy_1.deepExtend(undefined, 123), 123);
        chai_1.assert.strictEqual(deepCopy_1.deepExtend('was', 'abc'), 'abc');
    });
    it('Date', function () {
        var d = new Date();
        chai_1.assert.deepEqual(deepCopy_1.deepExtend(new Date(), d), d);
    });
    it('Object', function () {
        chai_1.assert.deepEqual(deepCopy_1.deepExtend({ old: 123 }, {}), { old: 123 });
        chai_1.assert.deepEqual(deepCopy_1.deepExtend({ old: 123 }, { s: 'hello' }), {
            old: 123,
            s: 'hello'
        });
        chai_1.assert.deepEqual(deepCopy_1.deepExtend({ old: 123, a: { c: 'in-old' } }, { a: { b: 123 } }), { old: 123, a: { b: 123, c: 'in-old' } });
    });
    it('Array', function () {
        chai_1.assert.deepEqual(deepCopy_1.deepExtend([1], []), []);
        chai_1.assert.deepEqual(deepCopy_1.deepExtend([1], [123, 456]), [123, 456]);
        chai_1.assert.deepEqual(deepCopy_1.deepExtend([1], [123, [456]]), [123, [456]]);
    });
    it('Array is copied - not referenced', function () {
        var o1 = { a: [1] };
        var o2 = { a: [2] };
        chai_1.assert.deepEqual(deepCopy_1.deepExtend(o1, o2), { a: [2] });
        o2.a.push(3);
        chai_1.assert.deepEqual(o1, { a: [2] });
    });
    it('Array with undefined elements', function () {
        var a = [];
        a[3] = '3';
        var b = deepCopy_1.deepExtend(undefined, a);
        chai_1.assert.deepEqual(b, [, , , '3']);
    });
    it('Function', function () {
        var source = function () {
            /*_*/
        };
        var target = deepCopy_1.deepExtend({
            a: function () {
                /*_*/
            }
        }, { a: source });
        chai_1.assert.deepEqual({ a: source }, target);
        chai_1.assert.strictEqual(source, target.a);
    });
});

//# sourceMappingURL=deepCopy.test.js.map
