module uim.cakellections;

use ArrayIterator;
use IteratorIterator;
use Serializable;

/**
 * A collection is an immutable list of elements with a handful of functions to
 * iterate, group, transform and extract information from it.
 */
class Collection : IteratorIterator : ICollection, Serializable {
    use CollectionTrait;

    /**
     * Constructor. You can provide an array or any traversable object
     *
     * @param iterable myItems Items.
     * @throws \InvalidArgumentException If passed incorrect type for items.
     */
    this(iterable myItems) {
        if (is_array(myItems)) {
            myItems = new ArrayIterator(myItems);
        }

        super.this(myItems);
    }

    // Returns a string representation of this object that can be used to reconstruct it
    string serialize() {
      return serialize(this.buffered());
    }

    /**
     * Returns an array for serializing this of this object.
     *
     * @return array
     */
    auto __serialize(): array {
        return this.buffered().toArray();
    }

    /**
     * Unserializes the passed string and rebuilds the Collection instance
     * @param string myCollection The serialized collection
     */
    void unserialize(myCollection) {
        this.this(unserialize(myCollection));
    }

    /**
     * Rebuilds the Collection instance.
     * @param array myData Data array.
     */
    void __unserialize(array myData) {
        this.this(myData);
    }

    // 
    size_t count() {
        myTraversable = this.optimizeUnwrap();

        if (is_array(myTraversable)) {
            return count(myTraversable);
        }

        return iterator_count(myTraversable);
    }

    /**
     * {@inheritDoc}
     *
     * @return int
     */
    insize_tt countKeys() {
        return count(this.toArray());
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    size_t[string] __debugInfo() {
      return ["count": this.count()];
    }
}
