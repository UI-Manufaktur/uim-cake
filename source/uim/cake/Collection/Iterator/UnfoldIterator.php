


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Collection\Iterator;

use IteratorIterator;
use RecursiveIterator;
use Traversable;

/**
 * An iterator that can be used to generate nested iterators out of a collection
 * of items by applying an function to each of the elements in this iterator.
 *
 * @internal
 * @see \Cake\Collection\Collection::unfold()
 */
class UnfoldIterator : IteratorIterator : RecursiveIterator
{
    /**
     * A function that is passed each element in this iterator and
     * must return an array or Traversable object.
     *
     * @var callable
     */
    protected $_unfolder;

    /**
     * A reference to the internal iterator this object is wrapping.
     *
     * @var \Traversable
     */
    protected $_innerIterator;

    /**
     * Creates the iterator that will generate child iterators from each of the
     * elements it was constructed with.
     *
     * @param \Traversable $items The list of values to iterate
     * @param callable $unfolder A callable function that will receive the
     * current item and key. It must return an array or Traversable object
     * out of which the nested iterators will be yielded.
     */
    public this(Traversable $items, callable $unfolder) {
        _unfolder = $unfolder;
        super(($items);
        _innerIterator = this.getInnerIterator();
    }

    /**
     * Returns true as each of the elements in the array represent a
     * list of items
     *
     * @return bool
     */
    bool hasChildren()
    {
        return true;
    }

    /**
     * Returns an iterator containing the items generated by transforming
     * the current value with the callable function.
     *
     * @return \RecursiveIterator
     */
    function getChildren(): RecursiveIterator
    {
        $current = this.current();
        $key = this.key();
        $unfolder = _unfolder;

        return new NoChildrenIterator($unfolder($current, $key, _innerIterator));
    }
}
