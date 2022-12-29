module uim.cake.orm.associations.collection;

@safe:
import uim.cake;

/**
 * A container/collection for association classes.
 *
 * Contains methods for managing associations, and
 * ordering operations around saving and deleting.
 */
class AssociationCollection : IteratorAggregate {

    /**
     * Stored associations
     *
     * @var array<\Cake\ORM\Association>
     */
    protected _items = [];

    /**
     * Constructor.
     *
     * Sets the default table locator for associations.
     * If no locator is provided, the global one will be used.
     *
     * @param uim.cake.ORM\Locator\ILocator|null myTableLocator Table locator instance.
     */
    this(?ILocator myTableLocator = null) {
        if (myTableLocator  !is null) {
            _tableLocator = myTableLocator;
        }
    }

    /**
     * Add an association to the collection
     *
     * If the alias added contains a `.` the part preceding the `.` will be dropped.
     * This makes using plugins simpler as the Plugin.Class syntax is frequently used.
     *
     * @param string myAlias The association alias
     * @param uim.cake.ORM\Association $association The association to add.
     * @return \Cake\ORM\Association The association object being added.
     */
    function add(string myAlias, Association $association): Association
    {
        [, myAlias] = pluginSplit(myAlias);

        return _items[myAlias] = $association;
    }

    /**
     * Creates and adds the Association object to this collection.
     *
     * @param string myClassName The name of association class.
     * @param string associated The alias for the target table.
     * @param array<string, mixed> myOptions List of options to configure the association definition.
     * @return \Cake\ORM\Association
     * @throws \InvalidArgumentException
     */
    function load(string myClassName, string associated, array myOptions = []): Association
    {
        myOptions += [
            "tableLocator":this.getTableLocator(),
        ];

        $association = new myClassName($associated, myOptions);
        if (!$association instanceof Association) {
            myMessage = sprintf(
                "The association must extend `%s` class, `%s` given.",
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
        return _items[myAlias] ?? null;
    }

    /**
     * Fetch an association by property name.
     *
     * @param string prop The property to find an association by.
     * @return \Cake\ORM\Association|null Either the association or null.
     */
    auto getByProperty(string prop): ?Association
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
     * @param string myAlias The association alias to get.
     * @return bool Whether the association exists.
     */
    bool has(string myAlias) {
        return isset(_items[myAlias]);
    }

    // Get the names of all the associations in the collection.
    string[] keys() {
        return array_keys(_items);
    }

    /**
     * Get an array of associations matching a specific type.
     *
     * @param array<string>|string myClass The type of associations you want.
     *   For example "BelongsTo" or array like ["BelongsTo", "HasOne"]
     * @return array<\Cake\ORM\Association> An array of Association objects.
     * @since 3.5.3
     */
    array getByType(myClass) {
        myClass = array_map("strtolower", (array)myClass);

        $out = array_filter(_items, function ($assoc) use (myClass) {
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
     */
    void remove(string myAlias) {
        unset(_items[myAlias]);
    }

    /**
     * Remove all registered associations.
     *
     * Once removed associations will no longer be reachable
     */
    void removeAll() {
        foreach (_items as myAlias: $object) {
            this.remove(myAlias);
        }
    }

    /**
     * Save all the associations that are parents of the given entity.
     *
     * Parent associations include any association where the given table
     * is the owning side.
     *
     * @param uim.cake.ORM\Table myTable The table entity is for.
     * @param uim.cake.Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save parents from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> myOptions The options for the save operation.
     * @return bool Success
     */
    bool saveParents(Table myTable, IEntity $entity, array $associations, array myOptions = []) {
        if (empty($associations)) {
            return true;
        }

        return _saveAssociations(myTable, $entity, $associations, myOptions, false);
    }

    /**
     * Save all the associations that are children of the given entity.
     *
     * Child associations include any association where the given table
     * is not the owning side.
     *
     * @param uim.cake.ORM\Table myTable The table entity is for.
     * @param uim.cake.Datasource\IEntity $entity The entity to save associated data for.
     * @param array $associations The list of associations to save children from.
     *   associations not in this list will not be saved.
     * @param array<string, mixed> myOptions The options for the save operation.
     * @return bool Success
     */
    bool saveChildren(Table myTable, IEntity $entity, array $associations, array myOptions) {
        if (empty($associations)) {
            return true;
        }

        return _saveAssociations(myTable, $entity, $associations, myOptions, true);
    }

    /**
     * Helper method for saving an association"s data.
     *
     * @param uim.cake.ORM\Table myTable The table the save is currently operating on
     * @param uim.cake.Datasource\IEntity $entity The entity to save
     * @param array $associations Array of associations to save.
     * @param array<string, mixed> myOptions Original options
     * @param bool $owningSide Compared with association classes"
     *   isOwningSide method.
     * @return bool Success
     * @throws \InvalidArgumentException When an unknown alias is used.
     */
    protected bool _saveAssociations(
        Table myTable,
        IEntity $entity,
        array $associations,
        array myOptions,
        bool $owningSide
    ) {
        unset(myOptions["associated"]);
        foreach ($associations as myAlias: $nested) {
            if (is_int(myAlias)) {
                myAlias = $nested;
                $nested = [];
            }
            $relation = this.get(myAlias);
            if (!$relation) {
                $msg = sprintf(
                    "Cannot save %s, it is not associated to %s",
                    myAlias,
                    myTable.getAlias()
                );
                throw new InvalidArgumentException($msg);
            }
            if ($relation.isOwningSide(myTable) != $owningSide) {
                continue;
            }
            if (!_save($relation, $entity, $nested, myOptions)) {
                return false;
            }
        }

        return true;
    }

    /**
     * Helper method for saving an association"s data.
     *
     * @param uim.cake.ORM\Association $association The association object to save with.
     * @param uim.cake.Datasource\IEntity $entity The entity to save
     * @param array<string, mixed> $nested Options for deeper associations
     * @param array<string, mixed> myOptions Original options
     * @return bool Success
     */
    protected bool _save(
        Association $association,
        IEntity $entity,
        array $nested,
        array myOptions
    ) {
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
     * @param uim.cake.Datasource\IEntity $entity The entity to delete associations for.
     * @param array<string, mixed> myOptions The options used in the delete operation.
     */
    bool cascadeDelete(IEntity $entity, array myOptions) {
        $noCascade = [];
        foreach (_items as $assoc) {
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
    array normalizeKeys(myKeys) {
        if (myKeys == true) {
            myKeys = this.keys();
        }

        if (empty(myKeys)) {
            return [];
        }

        return _normalizeAssociations(myKeys);
    }

    /**
     * Allow looping through the associations
     *
     * @return \Traversable<string, \Cake\ORM\Association>
     */
    Traversable getIterator() {
        return new ArrayIterator(_items);
    }
}
