module uim.cake.collections.iterators;

import uim.cake.collection\Collection;
use IDateTime;
use Traversable;

/**
 * An iterator that will return the passed items in order. The order is given by
 * the value returned in a callback function that maps each of the elements.
 *
 * ### Example:
 *
 * ```
 * myItems = [myUser1, myUser2, myUser3];
 * $sorted = new SortIterator(myItems, function (myUser) {
 *  return myUser.age;
 * });
 *
 * // output all user name order by their age in descending order
 * foreach ($sorted as myUser) {
 *  echo myUser.name;
 * }
 * ```
 *
 * This iterator does not preserve the keys passed in the original elements.
 */
class SortIterator : Collection
{
    /**
     * Wraps this iterator around the passed items so when iterated they are returned
     * in order.
     *
     * The callback will receive as first argument each of the elements in myItems,
     * the value returned in the callback will be used as the value for sorting such
     * element. Please note that the callback function could be called more than once
     * per element.
     *
     * @param iterable myItems The values to sort
     * @param callable|string $callback A function used to return the actual value to
     * be compared. It can also be a string representing the path to use to fetch a
     * column or property in each element
     * @param int $dir either SORT_DESC or SORT_ASC
     * @param int myType the type of comparison to perform, either SORT_STRING
     * SORT_NUMERIC or SORT_NATURAL
     */
    this(iterable myItems, $callback, int $dir = \SORT_DESC, int myType = \SORT_NUMERIC)
    {
        if (!is_array(myItems)) {
            myItems = iterator_to_array((new Collection(myItems)).unwrap(), false);
        }

        $callback = this._propertyExtractor($callback);
        myResults = [];
        foreach (myItems as myKey => $val) {
            $val = $callback($val);
            if ($val instanceof IDateTime && myType === \SORT_NUMERIC) {
                $val = $val.format('U');
            }
            myResults[myKey] = $val;
        }

        $dir === SORT_DESC ? arsort(myResults, myType) : asort(myResults, myType);

        foreach (array_keys(myResults) as myKey) {
            myResults[myKey] = myItems[myKey];
        }
        super.this(myResults);
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
