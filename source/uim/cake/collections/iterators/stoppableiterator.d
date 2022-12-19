module uim.cake.collections.iterators.stoppableiterator;

@safe:
import uim.cake;

/**
 * Creates an iterator from another iterator that will verify a condition on each
 * step. If the condition evaluates to false, the iterator will not yield more
 * results.
 *
 * @internal
 * @see \Cake\Collection\Collection::stopWhen()
 */
class StoppableIterator : Collection {
    /**
     * The condition to evaluate for each item of the collection
     *
     * @var callable
     */
    protected _condition;

    /**
     * A reference to the internal iterator this object is wrapping.
     *
     * @var \Traversable
     */
    protected _innerIterator;

    /**
     * Creates an iterator that can be stopped based on a condition provided by a callback.
     *
     * Each time the condition callback is executed it will receive the value of the element
     * in the current iteration, the key of the element and the passed myItems iterator
     * as arguments, in that order.
     *
     * @param iterable myItems The list of values to iterate
     * @param callable $condition A function that will be called for each item in
     * the collection, if the result evaluates to false, no more items will be
     * yielded from this iterator.
     */
    this(iterable myItems, callable $condition) {
        _condition = $condition;
        super.this(myItems);
        _innerIterator = this.getInnerIterator();
    }

    /**
     * Evaluates the condition and returns its result, this controls
     * whether more results will be yielded.
     */
    bool valid() {
        if (!super.valid()) {
            return false;
        }

        $current = this.current();
        myKey = this.key();
        $condition = _condition;

        return !$condition($current, myKey, _innerIterator);
    }


    Traversable unwrap() {
        $iterator = _innerIterator;

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) !== ArrayIterator::class) {
            return this;
        }

        // ArrayIterator can be traversed strictly.
        // Let"s do that for performance gains

        $callback = _condition;
        $res = [];

        foreach ($k: $v; $iterator) {
            if ($callback($v, $k, $iterator)) {
                break;
            }
            $res[$k] = $v;
        }

        return new ArrayIterator($res);
    }
}
