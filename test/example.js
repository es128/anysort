var anysort = require('..');

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

var matchers = [
	'path/to/file.js',
	'path/anyjs/**/*.js',
	/foo.js$/,
	function (string) {
		return string.indexOf('bar') !== -1 && string.length > 10
	}
];

sorted = unsorted.sort(anysort(matchers));
console.log(sorted);

sorted = unsorted.sort(function (a, b){
	return anysort(a, b, matchers);
});
console.log(sorted);

sorted = anysort.splice(unsorted, matchers);
console.log(sorted);

sorted = anysort.splice(unsorted, matchers).sorted;
console.log(sorted);

var before = /to/;
var after = ['path/anyjs/baz.js', 'path/anyjs/aaz.js'];
sorted = anysort.grouped(unsorted, [before, 'unmatched', after]);
console.log(sorted);

var exclusions = /anyjs/;
sorted = anysort.grouped(unsorted, [exclusions, matchers], [2, 1]);
console.log(sorted);
