module uim.cakeM;

import uim.caketasources\IEntity;
import uim.caketasources\EntityTrait;
import uim.caketasources\InvalidPropertyInterface;

/**
 * An entity represents a single result row from a repository. It exposes the
 * methods for retrieving and storing properties associated in this row.
 */
class Entity : IEntity, InvalidPropertyInterface
{
    use EntityTrait;

    /**
     * Initializes the internal properties of this entity out of the
     * keys in an array. The following list of options can be used:
     *
     * - useSetters: whether use internal setters for properties or not
     * - markClean: whether to mark all properties as clean after setting them
     * - markNew: whether this instance has not yet been persisted
     * - guard: whether to prevent inaccessible properties from being set (default: false)
     * - source: A string representing the alias of the repository this entity came from
     *
     * ### Example:
     *
     * ```
     *  $entity = new Entity(['id' => 1, 'name' => 'Andrew'])
     * ```
     *
     * @param array<string, mixed> $properties hash of properties to set in this entity
     * @param array<string, mixed> myOptions list of options to use when creating this entity
     */
    this(array $properties = [], array myOptions = []) {
        myOptions += [
            'useSetters' => true,
            'markClean' => false,
            'markNew' => null,
            'guard' => false,
            'source' => null,
        ];

        if (!empty(myOptions['source'])) {
            this.setSource(myOptions['source']);
        }

        if (myOptions['markNew'] !== null) {
            this.setNew(myOptions['markNew']);
        }

        if (!empty($properties) && myOptions['markClean'] && !myOptions['useSetters']) {
            this._fields = $properties;

            return;
        }

        if (!empty($properties)) {
            this.set($properties, [
                'setter' => myOptions['useSetters'],
                'guard' => myOptions['guard'],
            ]);
        }

        if (myOptions['markClean']) {
            this.clean();
        }
    }
}
