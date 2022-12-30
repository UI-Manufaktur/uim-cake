
module uim.cake.Collection\Iterator;

import uim.cake.Collection\Collection;
use Countable;
use Serializable;
use SplDoublyLinkedList;

/**
 * Creates an iterator from another iterator that will keep the results of the inner
 * iterator in memory, so that results don"t have to be re-calculated.
 */
class BufferedIterator : Collection : Countable, Serializable
{
    /**
     * The in-memory cache containing results from previous iterators
     *
     * @var \SplDoublyLinkedList
     */
    protected $_buffer;

    /**
     * Points to the next record number that should be fetched
     *
     */
    protected int $_index = 0;

    /**
     * Last record fetched from the inner iterator
     *
     * @var mixed
     */
    protected $_current;

    /**
     * Last key obtained from the inner iterator
     *
     * @var mixed
     */
    protected $_key;

    /**
     * Whether the internal iterator"s rewind method was already
     * called
     *
     */
    protected bool $_started = false;

    /**
     * Whether the internal iterator has reached its end.
     *
     */
    protected bool $_finished = false;

    /**
     * Maintains an in-memory cache of the results yielded by the internal
     * iterator.
     *
     * @param iterable $items The items to be filtered.
     */
    this(iterable $items) {
        _buffer = new SplDoublyLinkedList();
        super(($items);
    }

    /**
     * Returns the current key in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function key() {
        return _key;
    }

    /**
     * Returns the current record in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        return _current;
    }

    /**
     * Rewinds the collection
     */
    void rewind() {
        if (_index == 0 && !_started) {
            _started = true;
            parent::rewind();

            return;
        }

        _index = 0;
    }

    /**
     * Returns whether the iterator has more elements
     *
     * @return bool
     */
    function valid(): bool
    {
        if (_buffer.offsetExists(_index)) {
            $current = _buffer.offsetGet(_index);
            _current = $current["value"];
            _key = $current["key"];

            return true;
        }

        $valid = parent::valid();

        if ($valid) {
            _current = parent::current();
            _key = parent::key();
            _buffer.push([
                "key": _key,
                "value": _current,
            ]);
        }

        _finished = !$valid;

        return $valid;
    }

    /**
     * Advances the iterator pointer to the next element
     */
    void next() {
        _index++;

        // Don"t move inner iterator if we have more buffer
        if (_buffer.offsetExists(_index)) {
            return;
        }
        if (!_finished) {
            parent::next();
        }
    }

    /**
     * Returns the number or items in this collection
     *
     * @return int
     */
    function count(): int
    {
        if (!_started) {
            this.rewind();
        }

        while (this.valid()) {
            this.next();
        }

        return _buffer.count();
    }

    /**
     * Returns a string representation of this object that can be used
     * to reconstruct it
     */
    string serialize()
    {
        if (!_finished) {
            this.count();
        }

        return serialize(_buffer);
    }

    /**
     * Magic method used for serializing the iterator instance.
     */
    array __serialize(): array
    {
        if (!_finished) {
            this.count();
        }

        return iterator_to_array(_buffer);
    }

    /**
     * Unserializes the passed string and rebuilds the BufferedIterator instance
     *
     * @param string $collection The serialized buffer iterator
     */
    void unserialize($collection) {
        __construct([]);
        _buffer = unserialize($collection);
        _started = true;
        _finished = true;
    }

    /**
     * Magic method used to rebuild the iterator instance.
     *
     * @param array $data Data array.
     */
    void __unserialize(array $data) {
        __construct([]);

        foreach ($data as $value) {
            _buffer.push($value);
        }

        _started = true;
        _finished = true;
    }
}
