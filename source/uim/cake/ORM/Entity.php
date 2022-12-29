
module uim.cake.ORM;

import uim.cake.datasources.EntityInterface;
import uim.cake.datasources.EntityTrait;
import uim.cake.datasources.InvalidPropertyInterface;

/**
 * An entity represents a single result row from a repository. It exposes the
 * methods for retrieving and storing properties associated in this row.
 */
class Entity : EntityInterface, InvalidPropertyInterface
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
     *  $entity = new Entity(["id": 1, "name": "Andrew"])
     * ```
     *
     * @param array<string, mixed> $properties hash of properties to set in this entity
     * @param array<string, mixed> $options list of options to use when creating this entity
     */
    this(array $properties = [], array $options = []) {
        $options += [
            "useSetters": true,
            "markClean": false,
            "markNew": null,
            "guard": false,
            "source": null,
        ];

        if (!empty($options["source"])) {
            this.setSource($options["source"]);
        }

        if ($options["markNew"] != null) {
            this.setNew($options["markNew"]);
        }

        if (!empty($properties) && $options["markClean"] && !$options["useSetters"]) {
            _fields = $properties;

            return;
        }

        if (!empty($properties)) {
            this.set($properties, [
                "setter": $options["useSetters"],
                "guard": $options["guard"],
            ]);
        }

        if ($options["markClean"]) {
            this.clean();
        }
    }
}
