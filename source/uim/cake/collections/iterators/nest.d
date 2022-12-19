module uim.cake.collections.iterators.nest;

@safe:
import uim.cake;

// A type of collection that is aware of nested items and exposes methods to check or retrieve them
class NestIterator : Collection : RecursiveIterator {
    /**
     * The name of the property that contains the nested items for each element
     *
     * @var callable|string
     */
    protected $_nestKey;

    /**
     * Constructor
     *
     * @param iterable myItems Collection items.
     * @param callable|string nestKey the property that contains the nested items
     * If a callable is passed, it should return the childrens for the passed item
     */
    this(iterable myItems, $nestKey) {
        super.this(myItems);
        _nestKey = $nestKey;
    }

    // Returns a traversable containing the children for the current item
    RecursiveIterator getChildren() {
      $property = _propertyExtractor(_nestKey);

      return new static($property(this.current()), _nestKey);
    }

    /**
     * Returns true if there is an array or a traversable object stored under the
     * configured nestKey for the current item */
    bool hasChildren() {
        $property = _propertyExtractor(_nestKey);
        $children = $property(this.current());

        if (is_array($children)) {
            return !empty($children);
        }

        return $children instanceof Traversable;
    }
}
