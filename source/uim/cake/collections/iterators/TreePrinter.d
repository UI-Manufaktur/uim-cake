module uim.baklava.collections.iterators;

import uim.baklava.collection\ICollection;
import uim.baklava.collection\CollectionTrait;
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
     * @param \RecursiveIterator myItems The iterator to flatten.
     * @param callable|string myValuePath The property to extract or a callable to return
     * the display value.
     * @param callable|string myKeyPath The property to use as iteration key or a
     * callable returning the key value.
     * @param string $spacer The string to use for prefixing the values according to
     * their depth in the tree.
     * @param int myMode Iterator mode.
     */
    this(
        RecursiveIterator myItems,
        myValuePath,
        myKeyPath,
        string $spacer,
        int myMode = RecursiveIteratorIterator::SELF_FIRST
    ) {
        super.this(myItems, myMode);
        this._value = this._propertyExtractor(myValuePath);
        this._key = this._propertyExtractor(myKeyPath);
        this._spacer = $spacer;
    }

    /**
     * Returns the current iteration key
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function key() {
        $extractor = this._key;

        return $extractor(this._fetchCurrent(), super.key(), this);
    }

    /**
     * Returns the current iteration value
     *
     * @return string
     */
    string current() {
        $extractor = this._value;
        $current = this._fetchCurrent();
        $spacer = str_repeat(this._spacer, this.getDepth());

        return $spacer . $extractor($current, super.key(), this);
    }

    /**
     * Advances the cursor one position
     *
     * @return void
     */
    void next() {
        super.next();
        this._current = null;
    }

    /**
     * Returns the current iteration element and caches its value
     *
     * @return mixed
     */
    protected auto _fetchCurrent() {
        if (this._current !== null) {
            return this._current;
        }

        return this._current = super.current();
    }
}
