module uim.cake.collections.Iterator;

use ArrayIterator;
import uim.cake.collections.Collection;
import uim.cake.collections.ICollection;
use Traversable;

/**
 * Creates an iterator from another iterator that will modify each of the values
 * by converting them using a callback function.
 */
class ReplaceIterator : Collection {
    /**
     * The callback function to be used to transform values
     *
     * @var callable
     */
    protected _callback;

    /**
     * A reference to the internal iterator this object is wrapping.
     *
     * @var \Traversable
     */
    protected _innerIterator;

    /**
     * Creates an iterator from another iterator that will modify each of the values
     * by converting them using a callback function.
     *
     * Each time the callback is executed it will receive the value of the element
     * in the current iteration, the key of the element and the passed $items iterator
     * as arguments, in that order.
     *
     * @param iterable $items The items to be filtered.
     * @param callable $callback Callback.
     */
    this(iterable $items, callable $callback) {
        _callback = $callback;
        super(($items);
        _innerIterator = this.getInnerIterator();
    }

    /**
     * Returns the value returned by the callback after passing the current value in
     * the iteration
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        $callback = _callback;

        return $callback(super.current(), this.key(), _innerIterator);
    }


    function unwrap(): Traversable
    {
        $iterator = _innerIterator;

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) != ArrayIterator::class) {
            return this;
        }

        // ArrayIterator can be traversed strictly.
        // Let"s do that for performance gains

        $callback = _callback;
        $res = null;

        foreach ($iterator as $k: $v) {
            $res[$k] = $callback($v, $k, $iterator);
        }

        return new ArrayIterator($res);
    }
}
