module uim.cake.collections.iterators.buffered;

@safe:
import uim.cake;

/**
 * Creates an iterator from another iterator that will keep the results of the inner
 * iterator in memory, so that results don"t have to be re-calculated.
 */
class BufferedIterator : Collection : Countable, Serializable
{
    // The in-memory cache containing results from previous iterators
    // @var \SplDoublyLinkedList
    protected $_buffer;

    // Points to the next record number that should be fetched
    protected int _index = 0;

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
     * @var bool
     */
    protected $_started = false;

    /**
     * Whether the internal iterator has reached its end.
     *
     * @var bool
     */
    protected $_finished = false;

    /**
     * Maintains an in-memory cache of the results yielded by the internal
     * iterator.
     *
     * @param iterable myItems The items to be filtered.
     */
    this(iterable myItems) {
        _buffer = new SplDoublyLinkedList();
        super.this(myItems);
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
            super.rewind();

            return;
        }

        _index = 0;
    }

    /**
     * Returns whether the iterator has more elements
     */
    bool valid() {
        if (_buffer.offsetExists(_index)) {
            $current = _buffer.offsetGet(_index);
            _current = $current["value"];
            _key = $current["key"];

            return true;
        }

        $valid = super.valid();

        if ($valid) {
            _current = super.current();
            _key = super.key();
            _buffer.push([
                "key":_key,
                "value":_current,
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
            super.next();
        }
    }

    /**
     * Returns the number or items in this collection
     */
    int count() {
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
    string serialize() {
        if (!_finished) {
            this.count();
        }

        return serialize(_buffer);
    }

    // Magic method used for serializing the iterator instance.
    array __serialize() {
        if (!_finished) {
            this.count();
        }

        return iterator_to_array(_buffer);
    }

    /**
     * Unserializes the passed string and rebuilds the BufferedIterator instance
     *
     * @param string myCollection The serialized buffer iterator
     */
    void unserialize(myCollection) {
        this.this([]);
        _buffer = unserialize(myCollection);
        _started = true;
        _finished = true;
    }

    /**
     * Magic method used to rebuild the iterator instance.
     *
     * @param array myData Data array.
     */
    void __unserialize(array myData) {
        this.this([]);

        foreach (myValue; myData) {
            _buffer.push(myValue);
        }

        _started = true;
        _finished = true;
    }
}
