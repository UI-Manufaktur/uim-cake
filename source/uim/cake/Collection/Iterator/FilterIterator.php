


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
use CallbackFilterIterator;
use Iterator;
use Traversable;

/**
 * Creates a filtered iterator from another iterator. The filtering is done by
 * passing a callback function to each of the elements and taking them out if
 * it does not return true.
 */
class FilterIterator : Collection
{
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
     * in the current iteration, the key of the element and the passed $items iterator
     * as arguments, in that order.
     *
     * @param \Traversable|array $items The items to be filtered.
     * @param callable $callback Callback.
     */
    public this($items, callable $callback)
    {
        if (!$items instanceof Iterator) {
            $items = new Collection($items);
        }

        _callback = $callback;
        $wrapper = new CallbackFilterIterator($items, $callback);
        parent::__construct($wrapper);
    }

    /**
     * @inheritDoc
     */
    function unwrap(): Traversable
    {
        /** @var \IteratorIterator $filter */
        $filter = this.getInnerIterator();
        $iterator = $filter.getInnerIterator();

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) != ArrayIterator::class) {
            return $filter;
        }

        // ArrayIterator can be traversed strictly.
        // Let"s do that for performance gains
        $callback = _callback;
        $res = [];

        foreach ($iterator as $k: $v) {
            if ($callback($v, $k, $iterator)) {
                $res[$k] = $v;
            }
        }

        return new ArrayIterator($res);
    }
}
