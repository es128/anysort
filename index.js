'use strict';

const anymatch = require('anymatch');

const returnFalse = () => false;

const generateAnysort = (criteria = returnFalse) => {
  const matcher = anymatch(criteria);
  return function sorter(a, b, startIndex) {
    const indexOfA = matcher(a, true);
    const indexOfB = matcher(b, true);
    const hasA = indexOfA !== -1;
    const hasB = indexOfB !== -1;
    if (hasA && !hasB) {
      return -1;
    } else if (!hasA && hasB) {
      return 1;
    } else if (indexOfA !== indexOfB) {
      return indexOfA - indexOfB;
    } else if (a < b) {
      return -1;
    } else if (a > b) {
      return 1;
    } else {
      return 0;
    }
  };
}

// A/B comparison for use in an Array.sort callback
const anysort = (...args) => {
  if (args.length <= 1) {
    return generateAnysort(args[0]);
  } else {
    return generateAnysort(args[2])(args[0], args[1]);
  }
};

// given the sorting criteria and full array, returns the fully
// sorted array as well as separate matched and unmatched lists
function splice(array, criteria = returnFalse, tieBreakers) {
  const matcher = anymatch(criteria);
  let matched = array.filter(matcher);
  const unmatched = array.filter(function(s) {
    return matched.indexOf(s) === -1;
  }).sort();
  if (!Array.isArray(criteria)) { criteria = [criteria]; }
  // use [].concat.apply because criteria may or may not be an array
  matched = matched.sort(anysort([].concat.apply(criteria, tieBreakers)));
  const sorted = matched.concat(unmatched);
  return {matched, unmatched, sorted};
}
anysort.splice = splice;

// Does a full sort based on an array of criteria, plus the
// option to set the position of any unmatched items.
// Can be used with an anymatch-compatible criteria array,
// or an array of those arrays.
function grouped(array, groups, order) {
  if (!groups) { groups = [returnFalse]; }
  let sorted = [];
  let ordered = [];
  let remaining = array.slice();
  let unmatchedPosition = groups.indexOf('unmatched');
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
