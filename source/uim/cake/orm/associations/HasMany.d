module uim.cake.orm.associations;

@safe:
import uim.cake;

/**
 * Represents an N - 1 relationship where the target side of the relationship
 * will have one or multiple records per each one in the source side.
 *
 * An example of a HasMany association would be Author has many Articles.
 */
class HasMany : Association
{
    /**
     * Order in which target records should be returned
     *
     * @var mixed
     */
    protected $_sort;

    /**
     * The type of join to be used when adding the association to a query
     */
    protected string $_joinType = Query::JOIN_TYPE_INNER;

    /**
     * The strategy name to be used to fetch associated records.
     */
    protected string $_strategy = self::STRATEGY_SELECT;

    /**
     * Valid strategies for this type of association
     *
     * @var array<string>
     */
    protected $_validStrategies = [
        self::STRATEGY_SELECT,
        self::STRATEGY_SUBQUERY,
    ];

    /**
     * Saving strategy that will only append to the links set
     */
    public const string SAVE_APPEND = "append";

    /**
     * Saving strategy that will replace the links with the provided set
     */
    public const string SAVE_REPLACE = "replace";

    /**
     * Saving strategy to be used by this association
     */
    protected string $_saveStrategy = self::SAVE_APPEND;

    /**
     * Returns whether the passed table is the owning side for this
     * association. This means that rows in the "target" table would miss important
     * or required information if the row in "source" did not exist.
     *
     * @param \Cake\ORM\Table $side The potential Table with ownership
     */
    bool isOwningSide(Table $side) {
        return $side == this.getSource();
    }

    /**
     * Sets the strategy that should be used for saving.
     *
     * @param string $strategy the strategy name to be used
     * @throws \InvalidArgumentException if an invalid strategy name is passed
     * @return this
     */
    auto setSaveStrategy(string $strategy) {
        if (!in_array($strategy, [self::SAVE_APPEND, self::SAVE_REPLACE], true)) {
            $msg = sprintf("Invalid save strategy "%s"", $strategy);
            throw new InvalidArgumentException($msg);
        }

        this._saveStrategy = $strategy;

        return this;
    }

    /**
     * Gets the strategy that should be used for saving.
     *
     * @return string the strategy to be used for saving
     */
    string getSaveStrategy() {
        return this._saveStrategy;
    }

    /**
     * Takes an entity from the source table and looks if there is a field
     * matching the property name for this association. The found entity will be
     * saved on the target table for this association by passing supplied
     * `myOptions`
     *
     * @param \Cake\Datasource\IEntity $entity an entity from the source table
     * @param array<string, mixed> myOptions options to be passed to the save method in the target table
     * @return \Cake\Datasource\IEntity|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see \Cake\ORM\Table::save()
     * @throws \InvalidArgumentException when the association data cannot be traversed.
     */
    function saveAssociated(IEntity $entity, array myOptions = []) {
        myTargetEntities = $entity.get(this.getProperty());

        $isEmpty = in_array(myTargetEntities, [null, [], "", false], true);
        if ($isEmpty) {
            if (
                $entity.isNew() ||
                this.getSaveStrategy() !== self::SAVE_REPLACE
            ) {
                return $entity;
            }

            myTargetEntities = [];
        }

        if (!is_iterable(myTargetEntities)) {
            myName = this.getProperty();
            myMessage = sprintf("Could not save %s, it cannot be traversed", myName);
            throw new InvalidArgumentException(myMessage);
        }

        $foreignKeyReference = array_combine(
            (array)this.getForeignKey(),
            $entity.extract((array)this.getBindingKey())
        );

        myOptions["_sourceTable"] = this.getSource();

        if (
            this._saveStrategy == self::SAVE_REPLACE &&
            !this._unlinkAssociated($foreignKeyReference, $entity, this.getTarget(), myTargetEntities, myOptions)
        ) {
            return false;
        }

        if (!is_array(myTargetEntities)) {
            myTargetEntities = iterator_to_array(myTargetEntities);
        }
        if (!this._saveTarget($foreignKeyReference, $entity, myTargetEntities, myOptions)) {
            return false;
        }

        return $entity;
    }

    /**
     * Persists each of the entities into the target table and creates links between
     * the parent entity and each one of the saved target entities.
     *
     * @param array $foreignKeyReference The foreign key reference defining the link between the
     * target entity, and the parent entity.
     * @param \Cake\Datasource\IEntity $parentEntity The source entity containing the target
     * entities to be saved.
     * @param array $entities list of entities
     * to persist in target table and to link to the parent entity
     * @param array<string, mixed> myOptions list of options accepted by `Table::save()`.
     * @return bool `true` on success, `false` otherwise.
     */
    protected bool _saveTarget(
        array $foreignKeyReference,
        IEntity $parentEntity,
        array $entities,
        array myOptions
    ) {
        $foreignKey = array_keys($foreignKeyReference);
        myTable = this.getTarget();
        $original = $entities;

        foreach ($entities as $k: $entity) {
            if (!($entity instanceof IEntity)) {
                break;
            }

            if (!empty(myOptions["atomic"])) {
                $entity = clone $entity;
            }

            if ($foreignKeyReference !== $entity.extract($foreignKey)) {
                $entity.set($foreignKeyReference, ["guard":false]);
            }

            if (myTable.save($entity, myOptions)) {
                $entities[$k] = $entity;
                continue;
            }

            if (!empty(myOptions["atomic"])) {
                $original[$k].setErrors($entity.getErrors());
                if ($entity instanceof InvalidPropertyInterface) {
                    $original[$k].setInvalid($entity.getInvalid());
                }

                return false;
            }
        }

        $parentEntity.set(this.getProperty(), $entities);

        return true;
    }

    /**
     * Associates the source entity to each of the target entities provided.
     * When using this method, all entities in `myTargetEntities` will be appended to
     * the source entity"s property corresponding to this association object.
     *
     * This method does not check link uniqueness.
     * Changes are persisted in the database and also in the source entity.
     *
     * ### Example:
     *
     * ```
     * myUser = myUsers.get(1);
     * $allArticles = $articles.find("all").toArray();
     * myUsers.Articles.link(myUser, $allArticles);
     * ```
     *
     * `myUser.get("articles")` will contain all articles in `$allArticles` after linking
     *
     * @param \Cake\Datasource\IEntity $sourceEntity the row belonging to the `source` side
     * of this association
     * @param array myTargetEntities list of entities belonging to the `target` side
     * of this association
     * @param array<string, mixed> myOptions list of options to be passed to the internal `save` call
     * @return bool true on success, false otherwise
     */
    bool link(IEntity $sourceEntity, array myTargetEntities, array myOptions = []) {
        $saveStrategy = this.getSaveStrategy();
        this.setSaveStrategy(self::SAVE_APPEND);
        $property = this.getProperty();

        $currentEntities = array_unique(
            array_merge(
                (array)$sourceEntity.get($property),
                myTargetEntities
            )
        );

        $sourceEntity.set($property, $currentEntities);

        $savedEntity = this.getConnection().transactional(function () use ($sourceEntity, myOptions) {
            return this.saveAssociated($sourceEntity, myOptions);
        });

        $ok = ($savedEntity instanceof IEntity);

        this.setSaveStrategy($saveStrategy);

        if ($ok) {
            $sourceEntity.set($property, $savedEntity.get($property));
            $sourceEntity.setDirty($property, false);
        }

        return $ok;
    }

    /**
     * Removes all links between the passed source entity and each of the provided
     * target entities. This method assumes that all passed objects are already persisted
     * in the database and that each of them contain a primary key value.
     *
     * ### Options
     *
     * Additionally to the default options accepted by `Table::delete()`, the following
     * keys are supported:
     *
     * - cleanProperty: Whether to remove all the objects in `myTargetEntities` that
     * are stored in `$sourceEntity` (default: true)
     *
     * By default this method will unset each of the entity objects stored inside the
     * source entity.
     *
     * Changes are persisted in the database and also in the source entity.
     *
     * ### Example:
     *
     * ```
     * myUser = myUsers.get(1);
     * myUser.articles = [$article1, $article2, $article3, $article4];
     * myUsers.save(myUser, ["Associated":["Articles"]]);
     * $allArticles = [$article1, $article2, $article3];
     * myUsers.Articles.unlink(myUser, $allArticles);
     * ```
     *
     * `$article.get("articles")` will contain only `[$article4]` after deleting in the database
     *
     * @param \Cake\Datasource\IEntity $sourceEntity an entity persisted in the source table for
     * this association
     * @param array myTargetEntities list of entities persisted in the target table for
     * this association
     * @param array<string, mixed>|bool myOptions list of options to be passed to the internal `delete` call.
     *   If boolean it will be used a value for "cleanProperty" option.
     * @throws \InvalidArgumentException if non persisted entities are passed or if
     * any of them is lacking a primary key value
     * @return void
     */
    void unlink(IEntity $sourceEntity, array myTargetEntities, myOptions = []) {
        if (is_bool(myOptions)) {
            myOptions = [
                "cleanProperty":myOptions,
            ];
        } else {
            myOptions += ["cleanProperty":true];
        }
        if (count(myTargetEntities) == 0) {
            return;
        }

        $foreignKey = (array)this.getForeignKey();
        myTarget = this.getTarget();
        myTargetPrimaryKey = array_merge((array)myTarget.getPrimaryKey(), $foreignKey);
        $property = this.getProperty();

        $conditions = [
            "OR":(new Collection(myTargetEntities))
                .map(function ($entity) use (myTargetPrimaryKey) {
                    /** @var \Cake\Datasource\IEntity $entity */
                    return $entity.extract(myTargetPrimaryKey);
                })
                .toList(),
        ];

        this._unlink($foreignKey, myTarget, $conditions, myOptions);

        myResult = $sourceEntity.get($property);
        if (myOptions["cleanProperty"] && myResult !== null) {
            $sourceEntity.set(
                $property,
                (new Collection($sourceEntity.get($property)))
                .reject(
                    function ($assoc) use (myTargetEntities) {
                        return in_array($assoc, myTargetEntities);
                    }
                )
                .toList()
            );
        }

        $sourceEntity.setDirty($property, false);
    }

    /**
     * Replaces existing association links between the source entity and the target
     * with the ones passed. This method does a smart cleanup, links that are already
     * persisted and present in `myTargetEntities` will not be deleted, new links will
     * be created for the passed target entities that are not already in the database
     * and the rest will be removed.
     *
     * For example, if an author has many articles, such as "article1","article 2" and "article 3" and you pass
     * to this method an array containing the entities for articles "article 1" and "article 4",
     * only the link for "article 1" will be kept in database, the links for "article 2" and "article 3" will be
     * deleted and the link for "article 4" will be created.
     *
     * Existing links are not deleted and created again, they are either left untouched
     * or updated.
     *
     * This method does not check link uniqueness.
     *
     * On success, the passed `$sourceEntity` will contain `myTargetEntities` as value
     * in the corresponding property for this association.
     *
     * Additional options for new links to be saved can be passed in the third argument,
     * check `Table::save()` for information on the accepted options.
     *
     * ### Example:
     *
     * ```
     * $author.articles = [$article1, $article2, $article3, $article4];
     * $authors.save($author);
     * $articles = [$article1, $article3];
     * $authors.getAssociation("articles").replace($author, $articles);
     * ```
     *
     * `$author.get("articles")` will contain only `[$article1, $article3]` at the end
     *
     * @param \Cake\Datasource\IEntity $sourceEntity an entity persisted in the source table for
     * this association
     * @param array myTargetEntities list of entities from the target table to be linked
     * @param array<string, mixed> myOptions list of options to be passed to the internal `save`/`delete` calls
     * when persisting/updating new links, or deleting existing ones
     * @throws \InvalidArgumentException if non persisted entities are passed or if
     * any of them is lacking a primary key value
     * @return bool success
     */
    bool replace(IEntity $sourceEntity, array myTargetEntities, array myOptions = []) {
        $property = this.getProperty();
        $sourceEntity.set($property, myTargetEntities);
        $saveStrategy = this.getSaveStrategy();
        this.setSaveStrategy(self::SAVE_REPLACE);
        myResult = this.saveAssociated($sourceEntity, myOptions);
        $ok = (myResult instanceof IEntity);

        if ($ok) {
            $sourceEntity = myResult;
        }
        this.setSaveStrategy($saveStrategy);

        return $ok;
    }

    /**
     * Deletes/sets null the related objects according to the dependency between source and targets
     * and foreign key nullability. Skips deleting records present in $remainingEntities
     *
     * @param array $foreignKeyReference The foreign key reference defining the link between the
     * target entity, and the parent entity.
     * @param \Cake\Datasource\IEntity $entity the entity which should have its associated entities unassigned
     * @param \Cake\ORM\Table myTarget The associated table
     * @param iterable $remainingEntities Entities that should not be deleted
     * @param array<string, mixed> myOptions list of options accepted by `Table::delete()`
     * @return bool success
     */
    protected bool _unlinkAssociated(
        array $foreignKeyReference,
        IEntity $entity,
        Table myTarget,
        iterable $remainingEntities = [],
        array myOptions = []
    ) {
        $primaryKey = (array)myTarget.getPrimaryKey();
        $exclusions = new Collection($remainingEntities);
        $exclusions = $exclusions.map(
            function ($ent) use ($primaryKey) {
                /** @var \Cake\Datasource\IEntity $ent */
                return $ent.extract($primaryKey);
            }
        )
        .filter(
            function ($v) {
                return !in_array(null, $v, true);
            }
        )
        .toList();

        $conditions = $foreignKeyReference;

        if (count($exclusions) > 0) {
            $conditions = [
                "NOT":[
                    "OR":$exclusions,
                ],
                $foreignKeyReference,
            ];
        }

        return this._unlink(array_keys($foreignKeyReference), myTarget, $conditions, myOptions);
    }

    /**
     * Deletes/sets null the related objects matching $conditions.
     *
     * The action which is taken depends on the dependency between source and
     * targets and also on foreign key nullability.
     *
     * @param array $foreignKey array of foreign key properties
     * @param \Cake\ORM\Table myTarget The associated table
     * @param array $conditions The conditions that specifies what are the objects to be unlinked
     * @param array<string, mixed> myOptions list of options accepted by `Table::delete()`
     * @return bool success
     */
    protected bool _unlink(array $foreignKey, Table myTarget, array $conditions = [], array myOptions = []) {
        $mustBeDependent = (!this._foreignKeyAcceptsNull(myTarget, $foreignKey) || this.getDependent());

        if ($mustBeDependent) {
            if (this._cascadeCallbacks) {
                $conditions = new QueryExpression($conditions);
                $conditions.traverse(void ($entry) use (myTarget) {
                    if ($entry instanceof FieldInterface) {
                        myField = $entry.getField();
                        if (is_string(myField)) {
                            $entry.setField(myTarget.aliasField(myField));
                        }
                    }
                });
                myQuery = this.find().where($conditions);
                $ok = true;
                foreach (myQuery as $assoc) {
                    $ok = $ok && myTarget.delete($assoc, myOptions);
                }

                return $ok;
            }

            this.deleteAll($conditions);

            return true;
        }

        $updateFields = array_fill_keys($foreignKey, null);
        this.updateAll($updateFields, $conditions);

        return true;
    }

    /**
     * Checks the nullable flag of the foreign key
     *
     * @param \Cake\ORM\Table myTable the table containing the foreign key
     * @param array $properties the list of fields that compose the foreign key
     */
    protected bool _foreignKeyAcceptsNull(Table myTable, array $properties) {
        return !in_array(
            false,
            array_map(
                function ($prop) use (myTable) {
                    return myTable.getSchema().isNullable($prop);
                },
                $properties
            )
        );
    }

    /**
     * Get the relationship type.
     */
    string type() {
        return self::ONE_TO_MANY;
    }

    /**
     * Whether this association can be expressed directly in a query join
     *
     * @param array<string, mixed> myOptions custom options key that could alter the return value
     * @return bool if the "matching" key in $option is true then this function
     * will return true, false otherwise
     */
    bool canBeJoined(array myOptions = []) {
        return !empty(myOptions["matching"]);
    }

    // Gets the name of the field representing the foreign key to the source table.
    string[] getForeignKey() {
        if (this._foreignKey == null) {
            this._foreignKey = this._modelKey(this.getSource().getTable());
        }

        return this._foreignKey;
    }

    /**
     * Sets the sort order in which target records should be returned.
     *
     * @param mixed $sort A find() compatible order clause
     * @return this
     */
    auto setSort($sort) {
        this._sort = $sort;

        return this;
    }

    /**
     * Gets the sort order in which target records should be returned.
     *
     * @return mixed
     */
    auto getSort() {
        return this._sort;
    }


    function defaultRowValue(array $row, bool $joined): array
    {
        $sourceAlias = this.getSource().getAlias();
        if (isset($row[$sourceAlias])) {
            $row[$sourceAlias][this.getProperty()] = $joined ? null : [];
        }

        return $row;
    }

    /**
     * Parse extra options passed in the constructor.
     *
     * @param array<string, mixed> myOptions original list of options passed in constructor
     * @return void
     */
    protected void _options(array myOptions) {
        if (!empty(myOptions["saveStrategy"])) {
            this.setSaveStrategy(myOptions["saveStrategy"]);
        }
        if (isset(myOptions["sort"])) {
            this.setSort(myOptions["sort"]);
        }
    }


    Closure eagerLoader(array myOptions) {
        $loader = new SelectLoader([
            "alias":this.getAlias(),
            "sourceAlias":this.getSource().getAlias(),
            "targetAlias":this.getTarget().getAlias(),
            "foreignKey":this.getForeignKey(),
            "bindingKey":this.getBindingKey(),
            "strategy":this.getStrategy(),
            "associationType":this.type(),
            "sort":this.getSort(),
            "finder":[this, "find"],
        ]);

        return $loader.buildEagerLoader(myOptions);
    }


    bool cascadeDelete(IEntity $entity, array myOptions = []) {
        $helper = new DependentDeleteHelper();

        return $helper.cascadeDelete(this, $entity, myOptions);
    }
}
