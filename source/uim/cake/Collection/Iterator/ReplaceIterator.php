


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Collection\Iterator;

use ArrayIterator;
import uim.cake.Collection\Collection;
import uim.cake.Collection\ICollection;
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
     * in the current iteration, the key of the element and the passed $items iterator
     * as arguments, in that order.
     *
     * @param iterable $items The items to be filtered.
     * @param callable $callback Callback.
     */
    public this(iterable $items, callable $callback)
    {
        _callback = $callback;
        parent::__construct($items);
        _innerIterator = this.getInnerIterator();
    }

    /**
     * Returns the value returned by the callback after passing the current value in
     * the iteration
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current()
    {
        $callback = _callback;

        return $callback(parent::current(), this.key(), _innerIterator);
    }

    /**
     * @inheritDoc
     */
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
        $res = [];

        foreach ($iterator as $k: $v) {
            $res[$k] = $callback($v, $k, $iterator);
        }

        return new ArrayIterator($res);
    }
}
