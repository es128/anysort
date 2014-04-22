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
			'path/zjs/foo.js'
			'path/zjs/caz.js'
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
			assert.deepEqual matched, [sortable[0], sortable[6]]
			# with tieBreakers, sortable[6] wins
			{matched, unmatched, sorted} = anysort.splice sortable, matchers[3], matchers
			assert.deepEqual matched, [sortable[6], sortable[0]]
			# sortable[3] matches the tieBreakers, but isn't in the matched array
			assert anysort.match matchers, sortable[3]
			assert -1 isnt unmatched.indexOf sortable[3]

	describe '.grouped', ->
		before = /to/
		after = ['path/zjs/baz.js', 'path/zjs/aaz.js']

		it 'should require only the first argument (list)', ->
			assert.throws anysort.grouped
			assert.doesNotThrow -> anysort.grouped []

		it 'should return natively sorted list without matchers', ->
			assert anysort.grouped(sortable), sortable.sort()

		it 'should require groupedMatchers to be an array', ->
			assert.throws -> anysort.grouped sortable, before

		it 'should not mutate input list', ->
			sorted = anysort.grouped sortable, [before]
			assert.notDeepEqual sorted, sortable
			assert.equal sorted.length, sortable.length

		it 'should sort with groupedMatchers', ->
			sorted = anysort.grouped sortable, [before]
			{matched} = anysort.splice sortable, before
			assert.deepEqual matched, sorted[0...matched.length]

		it 'should allow nested arrays and non-arrays in groupedMatchers', ->
			sorted = anysort.grouped sortable, [before, after]
			matchedBefore = (anysort.splice sortable, before).matched
			matchedAfter  = (anysort.splice sortable, after ).matched
			start = matchedBefore.length
			end = start + matchedAfter.length
			assert.deepEqual matchedAfter, sorted[start...end]

		it 'should set unmatched position', ->
			sorted = anysort.grouped sortable, [before, 'unmatched', after]
			matchedBefore = (anysort.splice sortable, before).matched
			matchedAfter  = (anysort.splice sortable, after ).matched

			# matchedBefore at the front
			assert.deepEqual matchedBefore, sorted[0...matchedBefore.length]

			# matchedAfter at the end
			assert.deepEqual matchedAfter, sorted[sorted.length-matchedAfter.length..]

			# unmatched in the middle
			unmatched = sortable.sort().filter (item) ->
				item not in matchedBefore.concat matchedAfter
			assert.deepEqual unmatched,
				sorted[matchedBefore.length...sorted.length-matchedAfter.length]

		it 'should respect separate order definition', ->
			sortedWithUnmatched = anysort.grouped sortable, [before, 'unmatched', after]
			sortedWithOrder     = anysort.grouped sortable, [before, after], [0, 2, 1]
			assert.deepEqual sortedWithUnmatched, sortedWithOrder

		it 'should support exclusions', ->
			exclusions = /ba/
			sorted = anysort.grouped sortable, [exclusions, before, after], [1, 3, 2]
			assert sorted.length < sortable.length
