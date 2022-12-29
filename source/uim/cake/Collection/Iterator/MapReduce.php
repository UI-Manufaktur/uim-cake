
module uim.cake.Collection\Iterator;

use ArrayIterator;
use IteratorAggregate;
use LogicException;
use Traversable;

/**
 * : a simplistic version of the popular Map-Reduce algorithm. Acts
 * like an iterator for the original passed data after each result has been
 * processed, thus offering a transparent wrapper for results coming from any
 * source.
 */
class MapReduce : IteratorAggregate
{
    /**
     * Holds the shuffled results that were emitted from the map
     * phase
     *
     * @var array
     */
    protected $_intermediate = [];

    /**
     * Holds the results as emitted during the reduce phase
     *
     * @var array
     */
    protected $_result = [];

    /**
     * Whether the Map-Reduce routine has been executed already on the data
     *
     * @var bool
     */
    protected $_executed = false;

    /**
     * Holds the original data that needs to be processed
     *
     * @var \Traversable
     */
    protected $_data;

    /**
     * A callable that will be executed for each record in the original data
     *
     * @var callable
     */
    protected $_mapper;

    /**
     * A callable that will be executed for each intermediate record emitted during
     * the Map phase
     *
     * @var callable|null
     */
    protected $_reducer;

    /**
     * Count of elements emitted during the Reduce phase
     *
     * @var int
     */
    protected $_counter = 0;

    /**
     * Constructor
     *
     * ### Example:
     *
     * Separate all unique odd and even numbers in an array
     *
     * ```
     *  $data = new \ArrayObject([1, 2, 3, 4, 5, 3]);
     *  $mapper = function ($value, $key, $mr) {
     *      $type = ($value % 2 == 0) ? "even" : "odd";
     *      $mr.emitIntermediate($value, $type);
     *  };
     *
     *  $reducer = function ($numbers, $type, $mr) {
     *      $mr.emit(array_unique($numbers), $type);
     *  };
     *  $results = new MapReduce($data, $mapper, $reducer);
     * ```
     *
     * Previous example will generate the following result:
     *
     * ```
     *  ["odd": [1, 3, 5], "even": [2, 4]]
     * ```
     *
     * @param \Traversable $data the original data to be processed
     * @param callable $mapper the mapper callback. This function will receive 3 arguments.
     * The first one is the current value, second the current results key and third is
     * this class instance so you can call the result emitters.
     * @param callable|null $reducer the reducer callback. This function will receive 3 arguments.
     * The first one is the list of values inside a bucket, second one is the name
     * of the bucket that was created during the mapping phase and third one is an
     * instance of this class.
     */
    this(Traversable $data, callable $mapper, ?callable $reducer = null) {
        _data = $data;
        _mapper = $mapper;
        _reducer = $reducer;
    }

    /**
     * Returns an iterator with the end result of running the Map and Reduce
     * phases on the original data
     *
     * @return \Traversable
     */
    function getIterator(): Traversable
    {
        if (!_executed) {
            _execute();
        }

        return new ArrayIterator(_result);
    }

    /**
     * Appends a new record to the bucket labelled with $key, usually as a result
     * of mapping a single record from the original data.
     *
     * @param mixed $val The record itself to store in the bucket
     * @param mixed $bucket the name of the bucket where to put the record
     * @return void
     */
    void emitIntermediate($val, $bucket) {
        _intermediate[$bucket][] = $val;
    }

    /**
     * Appends a new record to the final list of results and optionally assign a key
     * for this record.
     *
     * @param mixed $val The value to be appended to the final list of results
     * @param mixed $key and optional key to assign to the value
     * @return void
     */
    void emit($val, $key = null) {
        _result[$key ?? _counter] = $val;
        _counter++;
    }

    /**
     * Runs the actual Map-Reduce algorithm. This is iterate the original data
     * and call the mapper function for each , then for each intermediate
     * bucket created during the Map phase call the reduce function.
     *
     * @return void
     * @throws \LogicException if emitIntermediate was called but no reducer function
     * was provided
     */
    protected void _execute() {
        $mapper = _mapper;
        foreach (_data as $key: $val) {
            $mapper($val, $key, this);
        }

        if (!empty(_intermediate) && empty(_reducer)) {
            throw new LogicException("No reducer function was provided");
        }

        /** @var callable $reducer */
        $reducer = _reducer;
        foreach (_intermediate as $key: $list) {
            $reducer($list, $key, this);
        }
        _intermediate = [];
        _executed = true;
    }
}
