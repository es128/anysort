anymatch = require 'anymatch'

# A/B comparison for use in an Array.sort callback
anysort = (criteria, a, b) ->
	matcher = anymatch.matcher criteria
	indexOfA = matcher a, true
	indexOfB = matcher b, true
	[hasA, hasB] = [(indexOfA isnt -1), (indexOfB isnt -1)]
	if hasA and not hasB
		-1
	else if not hasA and hasB
		1
	else if indexOfA isnt indexOfB
		indexOfA - indexOfB
	# when all else is equal, natural sort
	else if a < b
		-1
	else if a > b
		1
	else
		0

# expose anymatch methods
anysort.match   = anymatch
anysort.matcher = anymatch.matcher

# given the sorting criteria and full array, returns the fully
# sorted array as well as separate matched and unmatched lists
anysort.splice = splice = (criteria, array) ->
	matcher = anymatch.matcher criteria
	matched = array.filter matcher
	unmatched = array.filter (s) -> -1 is matched.indexOf s
	matched = matched.sort (a, b) -> anysort criteria, a, b
	{matched, unmatched, sorted: matched.concat unmatched}

# Does a full sort based on an array of criteria, plus the
# option to set the position of any unmatched items.
# Can be used with an anymatch-compatible criteria array,
# or an array of those arrays.
anysort.grouped = (groups, array) ->
	sorted = []
	before = null
	after = []
	remaining = array.slice()
	groups.forEach (criteria) ->
		if criteria is 'unmatched'
			before = sorted.slice()
			return sorted = []
		{matched, unmatched} = splice criteria, remaining
		sorted = sorted.concat matched
		remaining = unmatched
	if before
		after = sorted
	else
		before = sorted
	# natural (alphabetical) sort of remaining
	before.concat remaining.sort(), after

module.exports = anysort
