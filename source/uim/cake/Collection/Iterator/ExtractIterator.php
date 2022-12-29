
module uim.cake.Collection\Iterator;

use ArrayIterator;
import uim.cake.Collection\Collection;
import uim.cake.Collection\ICollection;
use Traversable;

/**
 * Creates an iterator from another iterator that extract the requested column
 * or property based on a path
 */
class ExtractIterator : Collection
{
    /**
     * A callable responsible for extracting a single value for each
     * item in the collection.
     *
     * @var callable
     */
    protected $_extractor;

    /**
     * Creates the iterator that will return the requested property for each value
     * in the collection expressed in $path
     *
     * ### Example:
     *
     * Extract the user name for all comments in the array:
     *
     * ```
     * $items = [
     *  ["comment": ["body": "cool", "user": ["name": "Mark"]],
     *  ["comment": ["body": "very cool", "user": ["name": "Renan"]]
     * ];
     * $extractor = new ExtractIterator($items, "comment.user.name"");
     * ```
     *
     * @param iterable $items The list of values to iterate
     * @param callable|string $path A dot separated path of column to follow
     * so that the final one can be returned or a callable that will take care
     * of doing that.
     */
    public this(iterable $items, $path) {
        _extractor = _propertyExtractor($path);
        super(($items);
    }

    /**
     * Returns the column value defined in $path or null if the path could not be
     * followed
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        $extractor = _extractor;

        return $extractor(parent::current());
    }


    function unwrap(): Traversable
    {
        $iterator = this.getInnerIterator();

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) != ArrayIterator::class) {
            return this;
        }

        // ArrayIterator can be traversed strictly.
        // Let"s do that for performance gains

        $callback = _extractor;
        $res = [];

        foreach ($iterator.getArrayCopy() as $k: $v) {
            $res[$k] = $callback($v);
        }

        return new ArrayIterator($res);
    }
}
