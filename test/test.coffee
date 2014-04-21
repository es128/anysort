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
		assert.deepEqual sortable.sort(anysort()), nativeSorted

	it 'should sort with matchers array', ->
		assert.notEqual sortable[0], matchers[0]
		assert.equal sortable.sort(anysort matchers)[0], matchers[0]

	it 'should sort with a single matcher', ->
		assert.notEqual sortable[0], matchers[0]
		assert.equal sortable.sort(anysort matchers[0])[0], matchers[0]
