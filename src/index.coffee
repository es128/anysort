anymatch = require 'anymatch'

returnFalse = -> false

generateAnysort = (criteria = returnFalse, tieBreakers) ->
	priMatcher = anymatch.matcher criteria
	if tieBreakers
		altMatcher = anymatch.matcher tieBreakers
	sorter = (a, b, useAlt) ->
		matcher = if useAlt then altMatcher else priMatcher
		indexOfA = matcher a, true
		indexOfB = matcher b, true
		[hasA, hasB] = [(indexOfA isnt -1), (indexOfB isnt -1)]
		if hasA and not hasB
			-1
		else if not hasA and hasB
			1
		else if indexOfA isnt indexOfB
			indexOfA - indexOfB
		else if tieBreakers and not useAlt
			sorter a, b, true
		# when all else is equal, natural sort
		else if a < b
			-1
		else if a > b
			1
		else
			0

# A/B comparison for use in an Array.sort callback
anysort = ->
	if arguments.length < 3
		# returns the callback
		generateAnysort arguments[0], arguments[1]
	else
		[a, b, criteria, tieBreakers] = arguments
		# returns the sorting int values
		generateAnysort(criteria, tieBreakers) a, b

# expose anymatch methods
anysort.match   = anymatch
anysort.matcher = anymatch.matcher

# given the sorting criteria and full array, returns the fully
# sorted array as well as separate matched and unmatched lists
anysort.splice = splice = (array, criteria = returnFalse, tieBreakers) ->
	matcher = anymatch.matcher criteria
	matched = array.filter matcher
	unmatched = array.filter (s) -> -1 is matched.indexOf s
	matched = matched.sort anysort criteria, tieBreakers
	{matched, unmatched, sorted: matched.concat unmatched}

# Does a full sort based on an array of criteria, plus the
# option to set the position of any unmatched items.
# Can be used with an anymatch-compatible criteria array,
# or an array of those arrays.
anysort.grouped = (array, groups = [returnFalse], order) ->
	sorted = []
	ordered = []
	remaining = array.slice()
	unmatchedPosition = groups.indexOf 'unmatched'

	groups.forEach (criteria, index) ->
		return if index is unmatchedPosition
		tieBreakers = []
		if index isnt groups.length - 1
			tieBreakers = groups.slice index + 1
			if index < unmatchedPosition
				tieBreakers.splice unmatchedPosition - index - 1, 1
			# shallow flatten
			tieBreakers = [].concat.apply [], tieBreakers
		{matched, unmatched} = splice remaining, criteria, tieBreakers
		sorted[index] = matched
		remaining = unmatched

	unmatchedPosition = sorted.length if unmatchedPosition is -1
	# natural (lexical/alphabetical) sort of remaining
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
