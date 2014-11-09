'use strict';

var anysort = require('./');
var anymatch = require('anymatch');
var assert = require('assert');

var sortable, nativeSorted, matchers;

describe('anysort', function() {
  beforeEach(function() {
    sortable = [
      'path/to/foo.js',
      'path/to/bar.js',
      'bar.js',
      'path/zjs/baz.js',
      'path/zjs/aaz.js',
      'path/to/file.js',
      'path/zjs/foo.js',
      'path/zjs/caz.js'
    ];
    nativeSorted = sortable.slice().sort();
    matchers = [
      'path/to/file.js',
      'path/zjs/**/*.js',
      'wontmatchanything',
      /foo.js$/,
      function(string) {
        return string.indexOf('bar') !== -1 && string.length > 10;
      }
    ];
  });

  it('should work as an Array.sort callback', function() {
    assert.notDeepEqual(sortable, nativeSorted);
    sortable.sort(anysort());
    assert.deepEqual(sortable, nativeSorted);
  });
  it('should sort with matchers array', function() {
    assert.notEqual(sortable[0], matchers[0]);
    assert.equal(sortable.sort(anysort(matchers))[0], matchers[0]);
    assert.notDeepEqual(sortable, nativeSorted);
  });
  it('should sort with a single matcher', function() {
    assert.notEqual(sortable[0], matchers[0]);
    assert.equal(sortable.sort(anysort(matchers[0]))[0], matchers[0]);
  });
  it('should break ties with lower matchers', function() {
    var val1 = 'path/zjs/foo.js';
    var val2 = 'path/zjs/aaz.js';
    assert(sortable.indexOf(val1) > sortable.indexOf(val2));
    sortable.sort(anysort(matchers[1])); // only the matcher they both hit
    assert(sortable.indexOf(val1) > sortable.indexOf(val2));
    // commenting out the /foo.js$/ matcher should cause this test to fail
    sortable.sort(anysort(matchers));
    assert(sortable.indexOf(val1) < sortable.indexOf(val2));
  });
  it('should be usable within a custom Array.sort callback', function() {
    var reverseSorted = sortable.slice().sort(function(a, b) {
      return anysort(b, a, matchers);
    });
    assert.deepEqual(reverseSorted, sortable.sort(anysort(matchers)).reverse());
  });

  describe('.splice', function() {
    it('should return an appropriate object', function() {
      var spliced = anysort.splice([]);
      assert(Array.isArray(spliced.matched));
      assert(Array.isArray(spliced.unmatched));
      assert(Array.isArray(spliced.sorted));
    });
    it('should work without matchers', function() {
      var spliced = anysort.splice(sortable);
      assert(spliced.matched.length === 0);
      assert(spliced.unmatched.length === sortable.length);
      assert.deepEqual(spliced.sorted, sortable.sort());
    });
    it('should utilize matchers', function() {
      var spliced = anysort.splice(sortable, matchers);
      assert(spliced.unmatched.length === 1);
      assert.deepEqual(spliced.sorted, spliced.matched.concat(spliced.unmatched));
      assert.deepEqual(spliced.sorted, sortable.sort(anysort(matchers)));
    });
    it('should utilize tieBreakers', function() {
      // without tieBreakers, sortable[0] comes first
      var tied = anysort.splice(sortable, matchers[3]).matched;
      assert.deepEqual(tied, [sortable[0], sortable[6]]);

      // with tieBreakers, sortable[6] wins
      var tieBroken = anysort.splice(sortable, matchers[3], matchers);
      assert.deepEqual(tieBroken.matched, [sortable[6], sortable[0]]);

      // sortable[3] matches the tieBreakers, but isn't in the matched array
      assert(anymatch(matchers, sortable[3]));
      assert(tieBroken.unmatched.indexOf(sortable[3]) !== -1);
    });
  });

  describe('.grouped', function() {
    var before = /to/;
    var after = [
      'path/zjs/baz.js',
      'path/zjs/aaz.js'
    ];
    it('should require only the first argument (list)', function() {
      assert.throws(anysort.grouped);
      assert.doesNotThrow(function() {
        anysort.grouped([]);
      });
    });
    it('should return natively sorted list without matchers', function() {
      assert(anysort.grouped(sortable), sortable.sort());
    });
    it('should require groupedMatchers to be an array', function() {
      assert.throws(function() {
        anysort.grouped(sortable, before);
      });
    });
    it('should not mutate input list', function() {
      var sorted = anysort.grouped(sortable, [before]);
      assert.notDeepEqual(sorted, sortable);
      assert.equal(sorted.length, sortable.length);
    });
    it('should sort with groupedMatchers', function() {
      var sorted = anysort.grouped(sortable, [before]);
      var matched = anysort.splice(sortable, before).matched;
      assert.deepEqual(matched, sorted.slice(0, matched.length));
    });
    it('should allow nested arrays and non-arrays in groupedMatchers', function() {
      var sorted = anysort.grouped(sortable, [before, after]);
      var matchedBefore = (anysort.splice(sortable, before)).matched;
      var matchedAfter = (anysort.splice(sortable, after)).matched;
      var start = matchedBefore.length;
      var end = start + matchedAfter.length;
      assert.deepEqual(matchedAfter, sorted.slice(start, end));
    });
    it('should set unmatched position', function() {
      var sorted = anysort.grouped(sortable, [before, 'unmatched', after]);
      var matchedBefore = (anysort.splice(sortable, before)).matched;
      var matchedAfter = (anysort.splice(sortable, after)).matched;

      // matchedBefore at the front
      assert.deepEqual(matchedBefore, sorted.slice(0, matchedBefore.length));

      // matchedAfter at the end
      assert.deepEqual(matchedAfter, sorted.slice(sorted.length - matchedAfter.length));

      // unmatched in the middle
      var unmatched = sortable.sort().filter(function(item) {
        return matchedBefore.concat(matchedAfter).indexOf(item) < 0;
      });
      assert.deepEqual(
        unmatched,
        sorted.slice(matchedBefore.length, sorted.length - matchedAfter.length)
      );
    });
    it('should respect separate order definition', function() {
      var sortedWithUnmatched = anysort.grouped(sortable, [before, 'unmatched', after]);
      var sortedWithOrder = anysort.grouped(sortable, [before, after], [0, 2, 1]);
      assert.deepEqual(sortedWithUnmatched, sortedWithOrder);
    });
    it('should support exclusions', function() {
      var exclusions = /ba/;
      var sorted = anysort.grouped(sortable, [exclusions, before, after], [1, 3, 2]);
      assert(sorted.length < sortable.length);
    });
    it('should break ties with lower matcher sets', function() {
      var tyingMatcher = /path.*a/;
      var moreMatchers1 = 'nonarraywontmatchanything';
      var moreMatchers2 = ['blah', /foo/, '**/caz.*'];
      var sorted = anysort.grouped(sortable, [tyingMatcher, moreMatchers1, moreMatchers2]);
      assert.equal(sorted[0], 'path/zjs/caz.js');
    });
  });
});
