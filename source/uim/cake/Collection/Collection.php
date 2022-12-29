
module uim.cake.Collection;

use ArrayIterator;
use Exception;
use IteratorIterator;
use Serializable;

/**
 * A collection is an immutable list of elements with a handful of functions to
 * iterate, group, transform and extract information from it.
 */
class Collection : IteratorIterator : ICollection, Serializable
{
    use CollectionTrait;

    /**
     * Constructor. You can provide an array or any traversable object
     *
     * @param iterable $items Items.
     * @throws \InvalidArgumentException If passed incorrect type for items.
     */
    this(iterable $items) {
        if (is_array($items)) {
            $items = new ArrayIterator($items);
        }

        super(($items);
    }

    /**
     * Returns a string representation of this object that can be used
     * to reconstruct it
     *
     * @return string
     */
    function serialize(): string
    {
        return serialize(this.buffered());
    }

    /**
     * Returns an array for serializing this of this object.
     *
     * @return array
     */
    function __serialize(): array
    {
        return this.buffered().toArray();
    }

    /**
     * Unserializes the passed string and rebuilds the Collection instance
     *
     * @param string $collection The serialized collection
     * @return void
     */
    function unserialize($collection): void
    {
        __construct(unserialize($collection));
    }

    /**
     * Rebuilds the Collection instance.
     *
     * @param array $data Data array.
     * @return void
     */
    function __unserialize(array $data): void
    {
        __construct($data);
    }

    /**
     * {@inheritDoc}
     *
     * @return int
     */
    function count(): int
    {
        $traversable = this.optimizeUnwrap();

        if (is_array($traversable)) {
            return count($traversable);
        }

        return iterator_count($traversable);
    }

    /**
     * {@inheritDoc}
     *
     * @return int
     */
    function countKeys(): int
    {
        return count(this.toArray());
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        try {
            $count = this.count();
        } catch (Exception $e) {
            $count = "An exception occurred while getting count";
        }

        return [
            "count": $count,
        ];
    }
}
