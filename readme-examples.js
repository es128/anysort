var assert = require('assert');
var inspect = require('util').inspect;
var i = function (val) {return inspect(val, {colors: true})};
var a = function (val) {return i(val).replace('[','[\n ').replace(' ]','\n]')};

var anysort = require('./');
console.log("var anysort = require('anysort');\n");

var sorted;
var unsorted = [
  'path/to/foo.js',
  'path/to/bar.js',
  'bar.js',
  'path/anyjs/baz.js',
  'path/anyjs/aaz.js',
  'path/to/file.js',
  'path/anyjs/caz.js'
];
console.log('var unsorted =', a(unsorted), ';\n');
var matchers = [
  'path/to/file.js',
  'path/anyjs/**/*.js',
  /foo.js$/,
  function (string) {
    return string.indexOf('bar') !== -1 && string.length > 10;
  }
];
console.log('var matchers =',
  a(matchers).replace('[Function]', matchers[3].toString()), ';\n');

// `.slice()` prevents `unsorted` from being mutated when using `.sort()`
sorted = unsorted.slice().sort(anysort(matchers));
assert.deepEqual(sorted, unsorted.slice().sort(function (a, b){
  return anysort(a, b, matchers);
}));
console.log('// the following two are equivalent');
console.log('unsorted.sort(anysort(matchers));');
console.log('unsorted.sort(function (a, b){');
console.log(' return anysort(a, b, matchers);');
console.log('});');
console.log(i(sorted), '\n');
/*
[ 'path/to/file.js',
  'path/anyjs/aaz.js',
  'path/anyjs/baz.js',
  'path/anyjs/caz.js',
  'path/to/foo.js',
  'path/to/bar.js',
  'bar.js' ]
*/

sorted = anysort.splice(unsorted, matchers);
console.log('anysort.splice(unsorted, matchers);');
console.log(i(sorted), '\n');
/*
{ matched:
   [ 'path/to/file.js',
     'path/anyjs/aaz.js',
     'path/anyjs/baz.js',
     'path/anyjs/caz.js',
     'path/to/foo.js',
     'path/to/bar.js' ],
  unmatched: [ 'bar.js' ],
  sorted:
   [ 'path/to/file.js',
     'path/anyjs/aaz.js',
     'path/anyjs/baz.js',
     'path/anyjs/caz.js',
     'path/to/foo.js',
     'path/to/bar.js',
     'bar.js' ] }
*/

sorted = anysort.splice(unsorted, matchers).sorted;
console.log('// quick access to just the sorted array');
console.log('anysort.splice(unsorted, matchers).sorted;');
console.log(i(sorted), '\n');
/*
[ 'path/to/file.js',
  'path/anyjs/aaz.js',
  'path/anyjs/baz.js',
  'path/anyjs/caz.js',
  'path/to/foo.js',
  'path/to/bar.js',
  'bar.js' ]
*/

var before = /to/;
var after = ['path/anyjs/baz.js', 'path/anyjs/aaz.js'];
sorted = anysort.grouped(unsorted, [before, 'unmatched', after]);
console.log("var before = /to/;");
console.log("var after = ['path/anyjs/baz.js', 'path/anyjs/aaz.js'];");
console.log("anysort.grouped(unsorted, [before, 'unmatched', after]);");
console.log(i(sorted), '\n');
/*
[ 'path/to/bar.js',
  'path/to/file.js',
  'path/to/foo.js',
  'bar.js',
  'path/anyjs/caz.js',
  'path/anyjs/baz.js',
  'path/anyjs/aaz.js' ]
*/

var exclusions = /anyjs/;
sorted = anysort.grouped(unsorted, [exclusions, matchers], [2, 1]);
console.log('var exclusions = /anyjs/;');
console.log('// 2 is the index for unmatched list members');
console.log('anysort.grouped(unsorted, [exclusions, matchers], [2, 1]);');
console.log(i(sorted), '\n');
/*
[ 'bar.js',
  'path/to/file.js',
  'path/to/foo.js',
  'path/to/bar.js' ]
*/
