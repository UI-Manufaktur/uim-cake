module uim.cake.collections.iterators.nochildreniterator;

@safe:
import uim.cake;

/**
 * An iterator that can be used as an argument for other iterators that require
 * a RecursiveIterator but do not want children. This iterator will
 * always behave as having no nested items.
 */
class NoChildrenIterator : Collection : RecursiveIterator
{
    /**
     * Returns false as there are no children iterators in this collection
     */
    bool hasChildren() {
        return false;
    }

    // Returns a self instance without any elements.
    RecursiveIterator getChildren() {
        return new static([]);
    }
}
