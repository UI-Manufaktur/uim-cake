module uim.cakellectionss.iterators;

use ArrayIterator;
import uim.cakellections\Collection;
import uim.cakellections\ICollection;
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
     * in the collection expressed in myPath
     *
     * ### Example:
     *
     * Extract the user name for all comments in the array:
     *
     * ```
     * myItems = [
     *  ['comment' => ['body' => 'cool', 'user' => ['name' => 'Mark']],
     *  ['comment' => ['body' => 'very cool', 'user' => ['name' => 'Renan']]
     * ];
     * $extractor = new ExtractIterator(myItems, 'comment.user.name'');
     * ```
     *
     * @param iterable myItems The list of values to iterate
     * @param callable|string myPath A dot separated path of column to follow
     * so that the final one can be returned or a callable that will take care
     * of doing that.
     */
    this(iterable myItems, myPath) {
        this._extractor = this._propertyExtractor(myPath);
        super.this(myItems);
    }

    /**
     * Returns the column value defined in myPath or null if the path could not be
     * followed
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        $extractor = this._extractor;

        return $extractor(super.current());
    }


    function unwrap(): Traversable
    {
        $iterator = this.getInnerIterator();

        if ($iterator instanceof ICollection) {
            $iterator = $iterator.unwrap();
        }

        if (get_class($iterator) !== ArrayIterator::class) {
            return this;
        }

        // ArrayIterator can be traversed strictly.
        // Let's do that for performance gains

        $callback = this._extractor;
        $res = [];

        foreach ($iterator.getArrayCopy() as $k => $v) {
            $res[$k] = $callback($v);
        }

        return new ArrayIterator($res);
    }
}
