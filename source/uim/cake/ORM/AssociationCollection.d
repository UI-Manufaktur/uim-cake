module uim.cake.ORM;

use ArrayIterator;
import uim.cake.Datasource\IEntity;
import uim.cake.orm.Locator\LocatorAwareTrait;
import uim.cake.orm.Locator\ILocator;
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
     * @var array<\Cake\ORM\Association>
     */
    protected $_items = [];

    /**
     * Constructor.
     *
     * Sets the default table locator for associations.
     * If no locator is provided, the global one will be used.
     *
     * @param \Cake\ORM\Locator\ILocator|null myTableLocator Table locator instance.
     */
    this(?ILocator myTableLocator = null) {
        if (myTableLocator !== null) {
            this._tableLocator = myTableLocator;
        }
    }

    /**
     * Add an association to the collection
     *
     * If the alias added contains a `.` the part preceding the `.` will be dropped.
     * This makes using plugins simpler as the Plugin.Class syntax is frequently used.
     *
     * @param string myAlias The association alias
     * @param \Cake\ORM\Association $association The association to add.
     * @return \Cake\ORM\Association The association object being added.
     */
    function add(string myAlias, Association $association): Association
    {
        [, myAlias] = pluginSplit(myAlias);

        return this._items[myAlias] = $association;
    }

    /**
     * Creates and adds the Association object to this collection.
     *
     * @param string myClassName The name of association class.
     * @param string $associated The alias for the target table.
     * @param array<string, mixed> myOptions List of options to configure the association definition.
     * @return \Cake\ORM\Association
     * @throws \InvalidArgumentException
     */
    function load(string myClassName, string $associated, array myOptions = []): Association
    {
        myOptions += [
            'tableLocator' => this.getTableLocator(),
        ];

        $association = new myClassName($associated, myOptions);
        if (!$association instanceof Association) {
            myMessage = sprintf(
                'The association must extend `%s` class, `%s` given.',
                Association::class,
                get_class($association)
            );
            throw new InvalidArgumentException(myMessage);
        }

        return this.add($association.getName(), $association);
    }

    /**
     * Fetch an attached association by name.
     *
     * @param string myAlias The association alias to get.
     * @return \Cake\ORM\Association|null Either the association or null.
     */
    auto get(string myAlias): ?Association
    {
        return this._items[myAlias] ?? null;
    }

    /**
     * Fetch an association by property name.
     *
     * @param string $prop The property to find an association by.
     * @return \Cake\ORM\Association|null Either the association or null.
     */
    auto getByProperty(string $prop): ?Association
    {
        foreach (this._items as $assoc) {
            if ($assoc.getProperty() === $prop) {
                return $assoc;
            }
        }

        return null;
    }

    /**
     * Check for an attached association by name.
     *
     * @param string myAlias The association alias to get.
     * @return bool Whether the association exists.
     */
    function has(string myAlias): bool
    {
        return isset(this._items[myAlias]);
    }

    /**
     * Get the names of all the associations in the collection.
     *
     * @return array<string>
     */
    function keys(): array
    {
        return array_keys(this._items);
    }

    /**
     * Get an array of associations matching a specific type.
     *
     * @param array<string>|string myClass The type of associations you want.
     *   For example 'BelongsTo' or array like ['BelongsTo', 'HasOne']
     * @return array<\Cake\ORM\Association> An array of Association objects.
     * @since 3.5.3
     */
    auto getByType(myClass): array
    {
        myClass = array_map('strtolower', (array)myClass);

        $out = array_filter(this._items, function ($assoc) use (myClass) {
            [, myName] = moduleSplit(get_class($assoc));

            return in_array(strtolower(myName), myClass, true);
        });

        return array_values($out);
    }

    /**
     * Drop/remove an association.
     *
     * Once removed the association will no longer be reachable
     *
     * @param string myAlias The alias name.
     * @return void
     */
    function remove(string myAlias): void
    {
        unset(this._items[myAlias]);
    }

    /**
     * Remove all registered associations.
     *
     * Once removed associations will no longer be reachable
     *
     * @return void
     */
    function removeAll(): void
    {
        foreach (this._items as myAlias => $object) {
            this.remove(myAlias);
        }
    }

    /**
     * Save all the associations that are parents of the given entity.
     *
     * Parent associations include any association where the given table
     * is the owning side.
     *
     * @param \Cake\ORM\Table myTable The table entity is for.
     * @param \Cake\Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save parents from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> myOptions The options for the save operation.
     * @return bool Success
     */
    function saveParents(Table myTable, IEntity $entity, array $associations, array myOptions = []): bool
    {
        if (empty($associations)) {
            return true;
        }

        return this._saveAssociations(myTable, $entity, $associations, myOptions, false);
    }

    /**
     * Save all the associations that are children of the given entity.
     *
     * Child associations include any association where the given table
     * is not the owning side.
     *
     * @param \Cake\ORM\Table myTable The table entity is for.
     * @param \Cake\Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save children from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> myOptions The options for the save operation.
     * @return bool Success
     */
    function saveChildren(Table myTable, IEntity $entity, array $associations, array myOptions): bool
    {
        if (empty($associations)) {
            return true;
        }

        return this._saveAssociations(myTable, $entity, $associations, myOptions, true);
    }

    /**
     * Helper method for saving an association's data.
     *
     * @param \Cake\ORM\Table myTable The table the save is currently operating on
     * @param \Cake\Datasource\IEntity $entity The entity to save
     * @param array $associations Array of associations to save.
     * @param array<string, mixed> myOptions Original options
     * @param bool $owningSide Compared with association classes'
     *   isOwningSide method.
     * @return bool Success
     * @throws \InvalidArgumentException When an unknown alias is used.
     */
    protected auto _saveAssociations(
        Table myTable,
        IEntity $entity,
        array $associations,
        array myOptions,
        bool $owningSide
    ): bool {
        unset(myOptions['associated']);
        foreach ($associations as myAlias => $nested) {
            if (is_int(myAlias)) {
                myAlias = $nested;
                $nested = [];
            }
            $relation = this.get(myAlias);
            if (!$relation) {
                $msg = sprintf(
                    'Cannot save %s, it is not associated to %s',
                    myAlias,
                    myTable.getAlias()
                );
                throw new InvalidArgumentException($msg);
            }
            if ($relation.isOwningSide(myTable) !== $owningSide) {
                continue;
            }
            if (!this._save($relation, $entity, $nested, myOptions)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Helper method for saving an association's data.
     *
     * @param \Cake\ORM\Association $association The association object to save with.
     * @param \Cake\Datasource\IEntity $entity The entity to save
     * @param array<string, mixed> $nested Options for deeper associations
     * @param array<string, mixed> myOptions Original options
     * @return bool Success
     */
    protected auto _save(
        Association $association,
        IEntity $entity,
        array $nested,
        array myOptions
    ): bool {
        if (!$entity.isDirty($association.getProperty())) {
            return true;
        }
        if (!empty($nested)) {
            myOptions = $nested + myOptions;
        }

        return (bool)$association.saveAssociated($entity, myOptions);
    }

    /**
     * Cascade a delete across the various associations.
     * Cascade first across associations for which cascadeCallbacks is true.
     *
     * @param \Cake\Datasource\IEntity $entity The entity to delete associations for.
     * @param array<string, mixed> myOptions The options used in the delete operation.
     * @return bool
     */
    function cascadeDelete(IEntity $entity, array myOptions): bool
    {
        $noCascade = [];
        foreach (this._items as $assoc) {
            if (!$assoc.getCascadeCallbacks()) {
                $noCascade[] = $assoc;
                continue;
            }
            $success = $assoc.cascadeDelete($entity, myOptions);
            if (!$success) {
                return false;
            }
        }

        foreach ($noCascade as $assoc) {
            $success = $assoc.cascadeDelete($entity, myOptions);
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
     * @param array|bool myKeys the list of association names to normalize
     * @return array
     */
    function normalizeKeys(myKeys): array
    {
        if (myKeys === true) {
            myKeys = this.keys();
        }

        if (empty(myKeys)) {
            return [];
        }

        return this._normalizeAssociations(myKeys);
    }

    /**
     * Allow looping through the associations
     *
     * @return \Traversable<string, \Cake\ORM\Association>
     */
    auto getIterator(): Traversable
    {
        return new ArrayIterator(this._items);
    }
}
