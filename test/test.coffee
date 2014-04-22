'use strict'

anysort = require '..'
assert = require 'assert'

sortable = nativeSorted = matchers = 0

describe 'anysort', ->

	beforeEach ->
		sortable = [
			'path/to/foo.js'
			'path/to/bar.js'
			'bar.js'
			'path/zjs/baz.js'
			'path/zjs/aaz.js'
			'path/to/file.js'
			'path/zjs/caz.js'
			'path/zjs/foo.js'
		]

		nativeSorted = sortable.slice().sort()

		matchers = [
			'path/to/file.js'
			'path/zjs/**/*.js'
			'wontmatchanything'
			/foo.js$/
			(string) -> string.indexOf('bar') isnt -1 and string.length > 10
		]

	it 'should work as an Array.sort callback', ->
		assert.notDeepEqual sortable, nativeSorted
		sortable.sort anysort()
		assert.deepEqual sortable, nativeSorted

	it 'should sort with matchers array', ->
		assert.notEqual sortable[0], matchers[0]
		assert.equal sortable.sort(anysort matchers)[0], matchers[0]
		assert.notDeepEqual sortable, nativeSorted

	it 'should sort with a single matcher', ->
		assert.notEqual sortable[0], matchers[0]
		assert.equal sortable.sort(anysort matchers[0])[0], matchers[0]

	it 'should break ties with lower matchers', ->
		val1 = 'path/zjs/foo.js'
		val2 = 'path/zjs/aaz.js'
		assert sortable.indexOf(val1) > sortable.indexOf(val2)
		sortable.sort anysort matchers[1] # only the matcher they both hit
		assert sortable.indexOf(val1) > sortable.indexOf(val2)
		# commenting out the /foo.js$/ matcher should cause this test to fail
		sortable.sort anysort matchers
		assert sortable.indexOf(val1) < sortable.indexOf(val2)

	it 'should be usable within a custom Array.sort callback', ->
		reverseSorted = sortable.slice().sort (a, b) -> anysort b, a, matchers
		assert.deepEqual reverseSorted, sortable.sort(anysort matchers).reverse()

	describe '.splice', ->
		it 'should return an appropriate object', ->
			{matched, unmatched, sorted} = anysort.splice []
			assert Array.isArray matched
			assert Array.isArray unmatched
			assert Array.isArray sorted

		it 'should work without matchers', ->
			{matched, unmatched, sorted} = anysort.splice sortable
			assert matched.length is 0
			assert unmatched.length is sortable.length
			assert.deepEqual sorted, sortable.sort()

		it 'should utilize matchers', ->
			{matched, unmatched, sorted} = anysort.splice sortable, matchers
			assert unmatched.length is 1
			assert.deepEqual sorted, matched.concat unmatched
			assert.deepEqual sorted, sortable.sort anysort matchers

		it 'should utilize tieBreakers', ->
			# without tieBreakers, sortable[0] comes first
			{matched, unmatched, sorted} = anysort.splice sortable, matchers[3]
			assert.deepEqual matched, [sortable[0], sortable[7]]
			# with tieBreakers, sortable[7] wins
			{matched, unmatched, sorted} = anysort.splice sortable, matchers[3], matchers
			assert.deepEqual matched, [sortable[7], sortable[0]]
			# sortable[3] matches the tieBreakers, but isn't in the matched array
			assert anysort.match matchers, sortable[3]
			assert -1 isnt unmatched.indexOf sortable[3]

	describe '.grouped', ->
		it 'should require only the first argument (list)', ->
			assert.throws anysort.grouped
			assert.doesNotThrow -> anysort.grouped []
