var anymatch = require('anymatch');

function returnFalse() { return false; }

function generateAnysort(criteria) {
  if (!criteria) { criteria = returnFalse; }
  var matcher = anymatch.matcher(criteria);
  return function sorter(a, b, startIndex) {
    var hasA, hasB, indexOfA, indexOfB;
    indexOfA = matcher(a, true, startIndex);
    indexOfB = matcher(b, true, startIndex);
    hasA = indexOfA !== -1;
    hasB = indexOfB !== -1;
    if (hasA && !hasB) {
      return -1;
    } else if (!hasA && hasB) {
      return 1;
    } else if (indexOfA !== indexOfB) {
      return indexOfA - indexOfB;
    } else if (hasA && hasB && indexOfA < criteria.length - 1) {
      return sorter(a, b, indexOfA + 1);
    } else if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else {
      return 0;
    }
  };
}

function anysort() {
  if (arguments.length === 1) {
    return generateAnysort(arguments[0]);
  } else {
    return generateAnysort(arguments[2])(arguments[0], arguments[1]);
  }
}

anysort.match = anymatch;

anysort.matcher = anymatch.matcher;

function splice(array, criteria, tieBreakers) {
  if (!criteria) { criteria = returnFalse; }
  var matcher = anymatch.matcher(criteria);
  var matched = array.filter(matcher);
  var unmatched = array.filter(function(s) {
    return matched.indexOf(s) === -1;
  }).sort();
  if (!Array.isArray(criteria)) { criteria = [criteria]; }
  matched = matched.sort(anysort([].concat.apply(criteria, tieBreakers)));
  return {
    matched: matched,
    unmatched: unmatched,
    sorted: matched.concat(unmatched)
  };
}
anysort.splice = splice;

function grouped(array, groups, order) {
  if (!groups) { groups = [returnFalse]; }
  var sorted = [];
  var ordered = [];
  var remaining = array.slice();
  var unmatchedPosition = groups.indexOf('unmatched');
  groups.forEach(function(criteria, index) {
    if (index === unmatchedPosition) { return; }
    var tieBreakers = [];
    if (index !== groups.length - 1) {
      tieBreakers = groups.slice(index + 1);
      if (index < unmatchedPosition) {
        tieBreakers.splice(unmatchedPosition - index - 1, 1);
      }
    }
    var spliced = splice(remaining, criteria, tieBreakers);
    var matched = spliced.matched;
    var unmatched = spliced.unmatched;
    sorted[index] = matched;
    remaining = unmatched;
  });
  if (unmatchedPosition === -1) { unmatchedPosition = sorted.length; }
  sorted[unmatchedPosition] = remaining;
  if (Array.isArray(order)) {
    order.forEach(function(position, index) {
      ordered[index] = sorted[position];
    });
  } else {
    ordered = sorted;
  }
  return ordered.reduce(function(flat, group) {
    return flat.concat(group);
  }, []);
}
anysort.grouped = grouped;

module.exports = anysort;
