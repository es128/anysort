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
			'path/anyjs/baz.js'
			'path/anyjs/aaz.js'
			'path/to/file.js'
			'path/anyjs/caz.js'
			'path/anyjs/foo.js'
		]

		nativeSorted = sortable.slice().sort()

		matchers = [
			'path/to/file.js'
			'path/anyjs/**/*.js'
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
		val1 = 'path/anyjs/foo.js'
		val2 = 'path/anyjs/aaz.js'
		assert sortable.indexOf(val1) > sortable.indexOf(val2)
		sortable.sort anysort matchers[1] # only the matcher they both hit
		assert sortable.indexOf(val1) > sortable.indexOf(val2)
		# commenting out the /foo.js$/ matcher should cause this test to fail
		sortable.sort anysort matchers
		assert sortable.indexOf(val1) < sortable.indexOf(val2)
