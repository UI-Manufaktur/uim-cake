module uim.cake.collections.Iterator;

import uim.cake.collections.Collection;
use DateTimeInterface;
use Traversable;

/**
 * An iterator that will return the passed items in order. The order is given by
 * the value returned in a callback function that maps each of the elements.
 *
 * ### Example:
 *
 * ```
 * $items = [$user1, $user2, $user3];
 * $sorted = new SortIterator($items, function ($user) {
 *  return $user.age;
 * });
 *
 * // output all user name order by their age in descending order
 * foreach ($sorted as $user) {
 *  echo $user.name;
 * }
 * ```
 *
 * This iterator does not preserve the keys passed in the original elements.
 */
class SortIterator : Collection {
    /**
     * Wraps this iterator around the passed items so when iterated they are returned
     * in order.
     *
     * The callback will receive as first argument each of the elements in $items,
     * the value returned in the callback will be used as the value for sorting such
     * element. Please note that the callback function could be called more than once
     * per element.
     *
     * @param iterable $items The values to sort
     * @param callable|string $callback A function used to return the actual value to
     * be compared. It can also be a string representing the path to use to fetch a
     * column or property in each element
     * @param int $dir either SORT_DESC or SORT_ASC
     * @param int $type the type of comparison to perform, either SORT_STRING
     * SORT_NUMERIC or SORT_NATURAL
     */
    this(iterable $items, $callback, int $dir = \SORT_DESC, int $type = \SORT_NUMERIC) {
        if (!is_array($items)) {
            $items = iterator_to_array((new Collection($items)).unwrap(), false);
        }

        $callback = _propertyExtractor($callback);
        $results = null;
        foreach ($items as $key: $val) {
            $val = $callback($val);
            if ($val instanceof DateTimeInterface && $type == \SORT_NUMERIC) {
                $val = $val.format("U");
            }
            $results[$key] = $val;
        }

        $dir == SORT_DESC ? arsort($results, $type) : asort($results, $type);

        foreach (array_keys($results) as $key) {
            $results[$key] = $items[$key];
        }
        super(($results);
    }

    /**
     * {@inheritDoc}
     *
     * @return \Traversable
     */
    function unwrap(): Traversable
    {
        return this.getInnerIterator();
    }
}
