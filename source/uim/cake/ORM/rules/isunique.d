module uim.cake.orm.Rule;

import uim.cake.datasources.IEntity;
import uim.cake.utilities.Hash;

/**
 * Checks that a list of fields from an entity are unique in the table
 */
class IsUnique
{
    /**
     * The list of fields to check
     *
     * @var array<string>
     */
    protected $_fields;

    /**
     * The unique check options
     *
     * @var array<string, mixed>
     */
    protected $_options = [
        "allowMultipleNulls": false,
    ];

    /**
     * Constructor.
     *
     * ### Options
     *
     * - `allowMultipleNulls` Allows any field to have multiple null values. Defaults to false.
     *
     * @param array<string> $fields The list of fields to check uniqueness for
     * @param array<string, mixed> $options The options for unique checks.
     */
    this(array $fields, array $options = []) {
        _fields = $fields;
        _options = $options + _options;
    }

    /**
     * Performs the uniqueness check
     *
     * @param uim.cake.Datasource\IEntity $entity The entity from where to extract the fields
     *   where the `repository` key is required.
     * @param array<string, mixed> $options Options passed to the check,
     */
    bool __invoke(IEntity $entity, array $options) {
        if (!$entity.extract(_fields, true)) {
            return true;
        }

        $fields = $entity.extract(_fields);
        if (_options["allowMultipleNulls"] && array_filter($fields, "is_null")) {
            return true;
        }

        $alias = $options["repository"].getAlias();
        $conditions = _alias($alias, $fields);
        if ($entity.isNew() == false) {
            $keys = (array)$options["repository"].getPrimaryKey();
            $keys = _alias($alias, $entity.extract($keys));
            if (Hash::filter($keys)) {
                $conditions["NOT"] = $keys;
            }
        }

        return !$options["repository"].exists($conditions);
    }

    /**
     * Add a model alias to all the keys in a set of conditions.
     *
     * @param string $alias The alias to add.
     * @param array $conditions The conditions to alias.
     * @return array<string, mixed>
     */
    protected array _alias(string $alias, array $conditions) {
        $aliased = [];
        foreach ($conditions as $key: $value) {
            $aliased["$alias.$key IS"] = $value;
        }

        return $aliased;
    }
}
