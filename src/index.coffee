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
	else if hasA and hasB
		indexOfA - indexOfB
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
	active = before = []
	after = []
	remaining = array.slice()
	groups.forEach (criteria) ->
		return active = after if criteria is 'unmatched'
		{matched, unmatched} = splice criteria, array
		active = active.concat matched
		remaining = unmatched
	# natural (alphabetical) sort of remaining
	sorted = remaining.sort (a, b) -> a < b
	before.concat sorted, after

module.exports = anysort
