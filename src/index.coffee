anymatch = require 'anymatch'

generateAnysort = (criteria = -> false) ->
	matcher = anymatch.matcher criteria
	(a, b) ->
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

# A/B comparison for use in an Array.sort callback
anysort = ->
	if arguments.length is 1
		# returns the callback
		generateAnysort arguments[0]
	else
		[a, b, criteria] = arguments
		# returns the sorting int values
		generateAnysort(criteria) a, b

# expose anymatch methods
anysort.match   = anymatch
anysort.matcher = anymatch.matcher

# given the sorting criteria and full array, returns the fully
# sorted array as well as separate matched and unmatched lists
anysort.splice = splice = (array, criteria = -> false) ->
	matcher = anymatch.matcher criteria
	matched = array.filter matcher
	unmatched = array.filter (s) -> -1 is matched.indexOf s
	matched = matched.sort anysort criteria
	{matched, unmatched, sorted: matched.concat unmatched}

# Does a full sort based on an array of criteria, plus the
# option to set the position of any unmatched items.
# Can be used with an anymatch-compatible criteria array,
# or an array of those arrays.
anysort.grouped = (array, groups = [-> false], order) ->
	sorted = []
	ordered = []
	remaining = array.slice()
	unmatchedPosition = groups.indexOf 'unmatched'

	groups.forEach (criteria, index) ->
		return if index is unmatchedPosition
		{matched, unmatched} = splice remaining, criteria
		sorted[index] = matched
		remaining = unmatched

	unmatchedPosition = sorted.length if unmatchedPosition is -1
	# natural (alphabetical) sort of remaining
	sorted[unmatchedPosition] = remaining.sort()

	if '[object Array]' is toString.call order
		order.forEach (position, index) ->
			ordered[index] = sorted[position]
	else
		ordered = sorted

	ordered.reduce (flat, group) ->
		flat.concat group
	, []

module.exports = anysort
