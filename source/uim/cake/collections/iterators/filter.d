module uim.cake.collections.iterators.filter;

@safe:
import uim.cake;

/**
 * Creates a filtered iterator from another iterator. The filtering is done by
 * passing a callback function to each of the elements and taking them out if
 * it does not return true.
 */
class FilterIterator : Collection {
    /**
     * The callback used to filter the elements in this collection
     *
     * @var callable
     */
    protected $_callback;

    /**
     * Creates a filtered iterator using the callback to determine which items are
     * accepted or rejected.
     *
     * Each time the callback is executed it will receive the value of the element
     * in the current iteration, the key of the element and the passed myItems iterator
     * as arguments, in that order.
     *
     * @param \Traversable|array myItems The items to be filtered.
     * @param callable $callback Callback.
     */
    this(myItems, callable $callback) {
        if (!myItems instanceof Iterator) {
            myItems = new Collection(myItems);
        }

        _callback = $callback;
        $wrapper = new CallbackFilterIterator(myItems, $callback);
        super.this($wrapper);
    }


    Traversable unwrap() {
        /** @var \IteratorIterator $filter */
        $filter = this.getInnerIterator();
        $iterator = $filter.getInnerIterator();

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) !== ArrayIterator::class) {
            return $filter;
        }

        // ArrayIterator can be traversed strictly.
        // Let"s do that for performance gains
        $callback = _callback;
        $res = [];

        foreach ($k, $v; $iterator) {
            if ($callback($v, $k, $iterator)) {
                $res[$k] = $v;
            }
        }

        return new ArrayIterator($res);
    }
}
