module uim.cake.ORM;

use ArrayIterator;
import uim.cake.datasources.IEntity;
import uim.cake.orm.locators.LocatorAwareTrait;
import uim.cake.orm.locators.ILocator;
use InvalidArgumentException;
use IteratorAggregate;
use Traversable;

/**
 * A container/collection for association classes.
 *
 * Contains methods for managing associations, and
 * ordering operations around saving and deleting.
 */
class AssociationCollection : IteratorAggregate
{
    use AssociationsNormalizerTrait;
    use LocatorAwareTrait;

    /**
     * Stored associations
     *
     * @var array<uim.cake.orm.Association>
     */
    protected $_items = [];

    /**
     * Constructor.
     *
     * Sets the default table locator for associations.
     * If no locator is provided, the global one will be used.
     *
     * @param uim.cake.orm.Locator\ILocator|null $tableLocator Table locator instance.
     */
    this(?ILocator $tableLocator = null) {
        if ($tableLocator != null) {
            _tableLocator = $tableLocator;
        }
    }

    /**
     * Add an association to the collection
     *
     * If the alias added contains a `.` the part preceding the `.` will be dropped.
     * This makes using plugins simpler as the Plugin.Class syntax is frequently used.
     *
     * @param string $alias The association alias
     * @param uim.cake.orm.Association $association The association to add.
     * @return uim.cake.orm.Association The association object being added.
     */
    function add(string $alias, Association $association): Association
    {
        [, $alias] = pluginSplit($alias);

        return _items[$alias] = $association;
    }

    /**
     * Creates and adds the Association object to this collection.
     *
     * @param string $className The name of association class.
     * @param string $associated The alias for the target table.
     * @param array<string, mixed> $options List of options to configure the association definition.
     * @return uim.cake.orm.Association
     * @throws \InvalidArgumentException
     * @psalm-param class-string<uim.cake.orm.Association> $className
     */
    function load(string $className, string $associated, array $options = []): Association
    {
        $options += [
            "tableLocator": this.getTableLocator(),
        ];

        $association = new $className($associated, $options);

        return this.add($association.getName(), $association);
    }

    /**
     * Fetch an attached association by name.
     *
     * @param string $alias The association alias to get.
     * @return uim.cake.orm.Association|null Either the association or null.
     */
    function get(string $alias): ?Association
    {
        return _items[$alias] ?? null;
    }

    /**
     * Fetch an association by property name.
     *
     * @param string $prop The property to find an association by.
     * @return uim.cake.orm.Association|null Either the association or null.
     */
    function getByProperty(string $prop): ?Association
    {
        foreach (_items as $assoc) {
            if ($assoc.getProperty() == $prop) {
                return $assoc;
            }
        }

        return null;
    }

    /**
     * Check for an attached association by name.
     *
     * @param string $alias The association alias to get.
     * @return bool Whether the association exists.
     */
    bool has(string $alias)
    {
        return isset(_items[$alias]);
    }

    /**
     * Get the names of all the associations in the collection.
     *
     * @return array<string>
     */
    function keys(): array
    {
        return array_keys(_items);
    }

    /**
     * Get an array of associations matching a specific type.
     *
     * @param array<string>|string $class The type of associations you want.
     *   For example "BelongsTo" or array like ["BelongsTo", "HasOne"]
     * @return array<uim.cake.orm.Association> An array of Association objects.
     * @since 3.5.3
     */
    function getByType($class): array
    {
        $class = array_map("strtolower", (array)$class);

        $out = array_filter(_items, function ($assoc) use ($class) {
            [, $name] = namespaceSplit(get_class($assoc));

            return in_array(strtolower($name), $class, true);
        });

        return array_values($out);
    }

    /**
     * Drop/remove an association.
     *
     * Once removed the association will no longer be reachable
     *
     * @param string $alias The alias name.
     */
    void remove(string $alias): void
    {
        unset(_items[$alias]);
    }

    /**
     * Remove all registered associations.
     *
     * Once removed associations will no longer be reachable
     */
    void removeAll(): void
    {
        foreach (_items as $alias: $object) {
            this.remove($alias);
        }
    }

    /**
     * Save all the associations that are parents of the given entity.
     *
     * Parent associations include any association where the given table
     * is the owning side.
     *
     * @param uim.cake.orm.Table $table The table entity is for.
     * @param uim.cake.Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save parents from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> $options The options for the save operation.
     * @return bool Success
     */
    bool saveParents(Table $table, IEntity $entity, array $associations, array $options = [])
    {
        if (empty($associations)) {
            return true;
        }

        return _saveAssociations($table, $entity, $associations, $options, false);
    }

    /**
     * Save all the associations that are children of the given entity.
     *
     * Child associations include any association where the given table
     * is not the owning side.
     *
     * @param uim.cake.orm.Table $table The table entity is for.
     * @param uim.cake.Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save children from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> $options The options for the save operation.
     * @return bool Success
     */
    bool saveChildren(Table $table, IEntity $entity, array $associations, array $options)
    {
        if (empty($associations)) {
            return true;
        }

        return _saveAssociations($table, $entity, $associations, $options, true);
    }

    /**
     * Helper method for saving an association"s data.
     *
     * @param uim.cake.orm.Table $table The table the save is currently operating on
     * @param uim.cake.Datasource\IEntity $entity The entity to save
     * @param array $associations Array of associations to save.
     * @param array<string, mixed> $options Original options
     * @param bool $owningSide Compared with association classes"
     *   isOwningSide method.
     * @return bool Success
     * @throws \InvalidArgumentException When an unknown alias is used.
     */
    protected bool _saveAssociations(
        Table $table,
        IEntity $entity,
        array $associations,
        array $options,
        bool $owningSide
    ) {
        unset($options["associated"]);
        foreach ($associations as $alias: $nested) {
            if (is_int($alias)) {
                $alias = $nested;
                $nested = [];
            }
            $relation = this.get($alias);
            if (!$relation) {
                $msg = sprintf(
                    "Cannot save %s, it is not associated to %s",
                    $alias,
                    $table.getAlias()
                );
                throw new InvalidArgumentException($msg);
            }
            if ($relation.isOwningSide($table) != $owningSide) {
                continue;
            }
            if (!_save($relation, $entity, $nested, $options)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Helper method for saving an association"s data.
     *
     * @param uim.cake.orm.Association $association The association object to save with.
     * @param uim.cake.Datasource\IEntity $entity The entity to save
     * @param array<string, mixed> $nested Options for deeper associations
     * @param array<string, mixed> $options Original options
     * @return bool Success
     */
    protected bool _save(
        Association $association,
        IEntity $entity,
        array $nested,
        array $options
    ) {
        if (!$entity.isDirty($association.getProperty())) {
            return true;
        }
        if (!empty($nested)) {
            $options = $nested + $options;
        }

        return (bool)$association.saveAssociated($entity, $options);
    }

    /**
     * Cascade a delete across the various associations.
     * Cascade first across associations for which cascadeCallbacks is true.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity to delete associations for.
     * @param array<string, mixed> $options The options used in the delete operation.
     */
    bool cascadeDelete(IEntity $entity, array $options)
    {
        $noCascade = [];
        foreach (_items as $assoc) {
            if (!$assoc.getCascadeCallbacks()) {
                $noCascade[] = $assoc;
                continue;
            }
            $success = $assoc.cascadeDelete($entity, $options);
            if (!$success) {
                return false;
            }
        }

        foreach ($noCascade as $assoc) {
            $success = $assoc.cascadeDelete($entity, $options);
            if (!$success) {
                return false;
            }
        }

        return true;
    }

    /**
     * Returns an associative array of association names out a mixed
     * array. If true is passed, then it returns all association names
     * in this collection.
     *
     * @param array|bool $keys the list of association names to normalize
     */
    array normalizeKeys($keys): array
    {
        if ($keys == true) {
            $keys = this.keys();
        }

        if (empty($keys)) {
            return [];
        }

        return _normalizeAssociations($keys);
    }

    /**
     * Allow looping through the associations
     *
     * @return \Traversable<string, uim.cake.orm.Association>
     */
    function getIterator(): Traversable
    {
        return new ArrayIterator(_items);
    }
}
