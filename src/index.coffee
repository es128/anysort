anymatch = require 'anymatch'

anysort = (criteria, a, b) ->
	matcher = anymatch.matcher criteria
	indexOfA = matcher a, true
	indexOfB = matcher b, true
	[hasA, hasB] = [(indexOfA isnt -1), (indexOfB isnt -1)]
	if hasA and not hasB
		-1
	else if not hasA and hasB
		1
	else if hasA and hasB
		indexOfA - indexOfB
	else
		0

anysort.match   = anymatch
anysort.matcher = anymatch.matcher

anysort.splice = (criteria, array) ->
	matcher = anymatch.matcher criteria
	matched = array.filter matcher
	unmatched = array.filter (s) -> -1 is matches.indexOf s
	matched = matched.sort (a, b) -> anysort criteria, a, b
	{matched, unmatched, sorted: matched.concat unmatched}

module.exports = anysort
