


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

use SplObjectStorage;

/**
 * Context tracking for Debugger::exportVar()
 *
 * This class is used by Debugger to track element depth, and
 * prevent cyclic references from being traversed multiple times.
 *
 * @internal
 */
class DebugContext
{
    /**
     * @var int
     */
    private $maxDepth;

    /**
     * @var int
     */
    private $depth = 0;

    /**
     * @var \SplObjectStorage
     */
    private $refs;

    /**
     * Constructor
     *
     * @param int $maxDepth The desired depth of dump output.
     */
    this(int $maxDepth) {
        this.maxDepth = $maxDepth;
        this.refs = new SplObjectStorage();
    }

    /**
     * Return a clone with increased depth.
     *
     * @return static
     */
    function withAddedDepth() {
        $new = clone this;
        $new.depth += 1;

        return $new;
    }

    /**
     * Get the remaining depth levels
     */
    int remainingDepth(): int
    {
        return this.maxDepth - this.depth;
    }

    /**
     * Get the reference ID for an object.
     *
     * If this object does not exist in the reference storage,
     * it will be added and the id will be returned.
     *
     * @param object $object The object to get a reference for.
     */
    int getReferenceId(object $object): int
    {
        if (this.refs.contains($object)) {
            return this.refs[$object];
        }
        $refId = this.refs.count();
        this.refs.attach($object, $refId);

        return $refId;
    }

    /**
     * Check whether an object has been seen before.
     *
     * @param object $object The object to get a reference for.
     */
    bool hasReference(object $object): bool
    {
        return this.refs.contains($object);
    }
}
