module uim.cake.collections.iterators;

import uim.cake.collection\ICollection;
import uim.cake.collection\CollectionTrait;
use RecursiveIterator;
use RecursiveIteratorIterator;

/**
 * A Recursive iterator used to flatten nested structures and also exposes
 * all Collection methods
 */
class TreeIterator : RecursiveIteratorIterator : ICollection
{
    use CollectionTrait;

    /**
     * The iteration mode
     *
     * @var int
     */
    protected $_mode;

    /**
     * Constructor
     *
     * @param \RecursiveIterator myItems The iterator to flatten.
     * @param int myMode Iterator mode.
     * @param int $flags Iterator flags.
     */
    this(
        RecursiveIterator myItems,
        int myMode = RecursiveIteratorIterator::SELF_FIRST,
        int $flags = 0
    ) {
        super.this(myItems, myMode, $flags);
        this._mode = myMode;
    }

    /**
     * Returns another iterator which will return the values ready to be displayed
     * to a user. It does so by extracting one property from each of the elements
     * and prefixing it with a spacer so that the relative position in the tree
     * can be visualized.
     *
     * Both myValuePath and myKeyPath can be a string with a property name to extract
     * or a dot separated path of properties that should be followed to get the last
     * one in the path.
     *
     * Alternatively, myValuePath and myKeyPath can be callable functions. They will get
     * the current element as first parameter, the current iteration key as second
     * parameter, and the iterator instance as third argument.
     *
     * ### Example
     *
     * ```
     *  $printer = (new Collection($treeStructure)).listNested().printer('name');
     * ```
     *
     * Using a closure:
     *
     * ```
     *  $printer = (new Collection($treeStructure))
     *      .listNested()
     *      .printer(function ($item, myKey, $iterator) {
     *          return $item.name;
     *      });
     * ```
     *
     * @param callable|string myValuePath The property to extract or a callable to return
     * the display value
     * @param callable|string|null myKeyPath The property to use as iteration key or a
     * callable returning the key value.
     * @param string $spacer The string to use for prefixing the values according to
     * their depth in the tree
     * @return \Cake\collection.iIterator\TreePrinter
     */
    function printer(myValuePath, myKeyPath = null, $spacer = '__') {
        if (!myKeyPath) {
            myCounter = 0;
            myKeyPath = function () use (&myCounter) {
                return myCounter++;
            };
        }

        return new TreePrinter(
            this.getInnerIterator(),
            myValuePath,
            myKeyPath,
            $spacer,
            this._mode
        );
    }
}
