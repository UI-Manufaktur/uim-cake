module uim.cake.collectionss.iterators;

import uim.cake.collections\Collection;
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
     * @var int
     */
    protected $_index = 0;

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
        this._buffer = new SplDoublyLinkedList();
        super.this(myItems);
    }

    /**
     * Returns the current key in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function key() {
        return this._key;
    }

    /**
     * Returns the current record in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        return this._current;
    }

    /**
     * Rewinds the collection
     */
    void rewind() {
        if (this._index === 0 && !this._started) {
            this._started = true;
            super.rewind();

            return;
        }

        this._index = 0;
    }

    /**
     * Returns whether the iterator has more elements
     */
    bool valid() {
        if (this._buffer.offsetExists(this._index)) {
            $current = this._buffer.offsetGet(this._index);
            this._current = $current["value"];
            this._key = $current["key"];

            return true;
        }

        $valid = super.valid();

        if ($valid) {
            this._current = super.current();
            this._key = super.key();
            this._buffer.push([
                "key" => this._key,
                "value" => this._current,
            ]);
        }

        this._finished = !$valid;

        return $valid;
    }

    /**
     * Advances the iterator pointer to the next element
     */
    void next() {
        this._index++;

        // Don"t move inner iterator if we have more buffer
        if (this._buffer.offsetExists(this._index)) {
            return;
        }
        if (!this._finished) {
            super.next();
        }
    }

    /**
     * Returns the number or items in this collection
     */
    int count() {
        if (!this._started) {
            this.rewind();
        }

        while (this.valid()) {
            this.next();
        }

        return this._buffer.count();
    }

    /**
     * Returns a string representation of this object that can be used
     * to reconstruct it
     */
    string serialize() {
        if (!this._finished) {
            this.count();
        }

        return serialize(this._buffer);
    }

    /**
     * Magic method used for serializing the iterator instance.
     *
     * @return array
     */
    auto __serialize(): array
    {
        if (!this._finished) {
            this.count();
        }

        return iterator_to_array(this._buffer);
    }

    /**
     * Unserializes the passed string and rebuilds the BufferedIterator instance
     *
     * @param string myCollection The serialized buffer iterator
     * @return void
     */
    void unserialize(myCollection) {
        this.this([]);
        this._buffer = unserialize(myCollection);
        this._started = true;
        this._finished = true;
    }

    /**
     * Magic method used to rebuild the iterator instance.
     *
     * @param array myData Data array.
     * @return void
     */
    void __unserialize(array myData) {
        this.this([]);

        foreach (myData as myValue) {
            this._buffer.push(myValue);
        }

        this._started = true;
        this._finished = true;
    }
}
