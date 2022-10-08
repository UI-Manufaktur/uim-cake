module uim.cake.collections.iterators;

use ArrayIterator;
import uim.cake.collection\Collection;
import uim.cake.collection\ICollection;
use Traversable;

/**
 * Creates an iterator from another iterator that will modify each of the values
 * by converting them using a callback function.
 */
class ReplaceIterator : Collection
{
    /**
     * The callback function to be used to transform values
     *
     * @var callable
     */
    protected $_callback;

    /**
     * A reference to the internal iterator this object is wrapping.
     *
     * @var \Traversable
     */
    protected $_innerIterator;

    /**
     * Creates an iterator from another iterator that will modify each of the values
     * by converting them using a callback function.
     *
     * Each time the callback is executed it will receive the value of the element
     * in the current iteration, the key of the element and the passed myItems iterator
     * as arguments, in that order.
     *
     * @param iterable myItems The items to be filtered.
     * @param callable $callback Callback.
     */
    this(iterable myItems, callable $callback) {
        this._callback = $callback;
        super.this(myItems);
        this._innerIterator = this.getInnerIterator();
    }

    /**
     * Returns the value returned by the callback after passing the current value in
     * the iteration
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        $callback = this._callback;

        return $callback(super.current(), this.key(), this._innerIterator);
    }


    function unwrap(): Traversable
    {
        $iterator = this._innerIterator;

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) !== ArrayIterator::class) {
            return this;
        }

        // ArrayIterator can be traversed strictly.
        // Let's do that for performance gains

        $callback = this._callback;
        $res = [];

        foreach ($iterator as $k => $v) {
            $res[$k] = $callback($v, $k, $iterator);
        }

        return new ArrayIterator($res);
    }
}
