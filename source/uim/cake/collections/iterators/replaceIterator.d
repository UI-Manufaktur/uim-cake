module uim.cake.collections.iterators.replaceiterator;

@safe:
import uim.cake;

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

    // A reference to the internal iterator this object is wrapping.
    protected Traversable $_innerIterator;

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
        _callback = $callback;
        super.this(myItems);
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

      $callback = _callback;
      $res = [];

      foreach ($k, $v; $iterator) {
          $res[$k] = $callback($v, $k, $iterator);
      }

      return new ArrayIterator($res);
    }
}
