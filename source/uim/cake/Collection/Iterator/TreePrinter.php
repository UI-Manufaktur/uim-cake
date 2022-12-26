


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Collection\Iterator;

import uim.cake.Collection\ICollection;
import uim.cake.Collection\CollectionTrait;
use RecursiveIterator;
use RecursiveIteratorIterator;

/**
 * Iterator for flattening elements in a tree structure while adding some
 * visual markers for their relative position in the tree
 */
class TreePrinter : RecursiveIteratorIterator : ICollection
{
    use CollectionTrait;

    /**
     * A callable to generate the iteration key
     *
     * @var callable
     */
    protected $_key;

    /**
     * A callable to extract the display value
     *
     * @var callable
     */
    protected $_value;

    /**
     * Cached value for the current iteration element
     *
     * @var mixed
     */
    protected $_current;

    /**
     * The string to use for prefixing the values according to their depth in the tree.
     *
     * @var string
     */
    protected $_spacer;

    /**
     * Constructor
     *
     * @param \RecursiveIterator $items The iterator to flatten.
     * @param callable|string $valuePath The property to extract or a callable to return
     * the display value.
     * @param callable|string $keyPath The property to use as iteration key or a
     * callable returning the key value.
     * @param string $spacer The string to use for prefixing the values according to
     * their depth in the tree.
     * @param int $mode Iterator mode.
     */
    public this(
        RecursiveIterator $items,
        $valuePath,
        $keyPath,
        string $spacer,
        int $mode = RecursiveIteratorIterator::SELF_FIRST
    ) {
        super(($items, $mode);
        _value = _propertyExtractor($valuePath);
        _key = _propertyExtractor($keyPath);
        _spacer = $spacer;
    }

    /**
     * Returns the current iteration key
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function key() {
        $extractor = _key;

        return $extractor(_fetchCurrent(), parent::key(), this);
    }

    /**
     * Returns the current iteration value
     *
     * @return string
     */
    function current(): string
    {
        $extractor = _value;
        $current = _fetchCurrent();
        $spacer = str_repeat(_spacer, this.getDepth());

        return $spacer . $extractor($current, parent::key(), this);
    }

    /**
     * Advances the cursor one position
     *
     * @return void
     */
    function next(): void
    {
        parent::next();
        _current = null;
    }

    /**
     * Returns the current iteration element and caches its value
     *
     * @return mixed
     */
    protected function _fetchCurrent() {
        if (_current != null) {
            return _current;
        }

        return _current = parent::current();
    }
}
