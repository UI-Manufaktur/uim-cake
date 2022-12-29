module uim.cake.orm.associations;

@safe:
import uim.cake;

/**
 * Represents an M - N relationship where there exists a junction - or join - table
 * that contains the association fields between the source and the target table.
 *
 * An example of a BelongsToMany association would be Article belongs to many Tags.
 */
class BelongsToMany : Association
{
    // -----------

    /**
     * The type of join to be used when adding the association to a query
     */
    protected string _joinType = Query::JOIN_TYPE_INNER;

    /**
     * The strategy name to be used to fetch associated records.
     */
    protected string _strategy = self::STRATEGY_SELECT;

    /**
     * Junction table instance
     *
     * @var uim.cake.ORM\Table
     */
    protected _junctionTable;

    // Junction table name
    protected string _junctionTableName;

    /**
     * The name of the hasMany association from the target table
     * to the junction table
     */
    protected string _junctionAssociationName;

    /**
     * The name of the property to be set containing data from the junction table
     * once a record from the target table is hydrated
     */
    protected string _junctionProperty = "_joinData";

    // Saving strategy to be used by this association
    protected string _saveStrategy = self::SAVE_REPLACE;

    /**
     * The name of the field representing the foreign key to the target table
     *
     * @var array<string>|string|null
     */
    protected _targetForeignKey;

    /**
     * The table instance for the junction relation.
     *
     * @var uim.cake.ORM\Table|string
     */
    protected _through;

    // Valid strategies for this type of association
    protected string[] _validStrategies = [
        self::STRATEGY_SELECT,
        self::STRATEGY_SUBQUERY,
    ];

    /**
     * Whether the records on the joint table should be removed when a record
     * on the source table is deleted.
     *
     * Defaults to true for backwards compatibility.
     *
     * @var bool
     */
    protected _dependent = true;

    /**
     * Filtered conditions that reference the target table.
     *
     * @var array|null
     */
    protected _targetConditions;

    /**
     * Filtered conditions that reference the junction table.
     *
     * @var array|null
     */
    protected _junctionConditions;

    /**
     * Order in which target records should be returned
     *
     * @var mixed
     */
    protected _sort;

    /**
     * Sets the name of the field representing the foreign key to the target table.
     *
     * @param array<string>|string myKey the key to be used to link both tables together
     * @return this
     */
    auto setTargetForeignKey(myKey) {
        _targetForeignKey = myKey;

        return this;
    }

    // Gets the name of the field representing the foreign key to the target table.
    string[] getTargetForeignKey() {
        if (_targetForeignKey is null) {
            _targetForeignKey = _modelKey(this.getTarget().getAlias());
        }

        return _targetForeignKey;
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
        if (_foreignKey is null) {
            _foreignKey = _modelKey(this.getSource().getTable());
        }

        return _foreignKey;
    }

    /**
     * Sets the sort order in which target records should be returned.
     *
     * @param mixed $sort A find() compatible order clause
     * @return this
     */
    auto setSort($sort) {
        _sort = $sort;

        return this;
    }

    /**
     * Gets the sort order in which target records should be returned.
     *
     * @return mixed
     */
    auto getSort() {
        return _sort;
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
     * Sets the table instance for the junction relation. If no arguments
     * are passed, the current configured table instance is returned
     *
     * @param uim.cake.ORM\Table|string|null myTable Name or instance for the join table
     * @return uim.cake.ORM\Table
     * @throws \InvalidArgumentException If the expected associations are incompatible with existing associations.
     */
    function junction(myTable = null): Table
    {
        if (myTable is null && _junctionTable  !is null) {
            return _junctionTable;
        }

        myTableLocator = this.getTableLocator();
        if (myTable is null && _through) {
            myTable = _through;
        } elseif (myTable is null) {
            myTableName = _junctionTableName();
            myTableAlias = Inflector::camelize(myTableName);

            myConfig = [];
            if (!myTableLocator.exists(myTableAlias)) {
                myConfig = ["table":myTableName, "allowFallbackClass":true];

                // Propagate the connection if we"ll get an auto-model
                if (!App::className(myTableAlias, "Model/Table", "Table")) {
                    myConfig["connection"] = this.getSource().getConnection();
                }
            }
            myTable = myTableLocator.get(myTableAlias, myConfig);
        }

        if (is_string(myTable)) {
            myTable = myTableLocator.get(myTable);
        }

        $source = this.getSource();
        myTarget = this.getTarget();
        if ($source.getAlias() == myTarget.getAlias()) {
            throw new InvalidArgumentException(sprintf(
                "The `%s` association on `%s` cannot target the same table.",
                this.getName(),
                $source.getAlias()
            ));
        }

        _generateSourceAssociations(myTable, $source);
        _generateTargetAssociations(myTable, $source, myTarget);
        _generateJunctionAssociations(myTable, $source, myTarget);

        return _junctionTable = myTable;
    }

    /**
     * Generate reciprocal associations as necessary.
     *
     * Generates the following associations:
     *
     * - target hasMany junction e.g. Articles hasMany ArticlesTags
     * - target belongsToMany source e.g Articles belongsToMany Tags.
     *
     * You can override these generated associations by defining associations
     * with the correct aliases.
     *
     * @param uim.cake.ORM\Table $junction The junction table.
     * @param uim.cake.ORM\Table $source The source table.
     * @param uim.cake.ORM\Table myTarget The target table.
     * @return void
     */
    protected void _generateTargetAssociations(Table $junction, Table $source, Table myTarget) {
        $junctionAlias = $junction.getAlias();
        $sAlias = $source.getAlias();
        $tAlias = myTarget.getAlias();

        myTargetBindingKey = null;
        if ($junction.hasAssociation($tAlias)) {
            myTargetBindingKey = $junction.getAssociation($tAlias).getBindingKey();
        }

        if (!myTarget.hasAssociation($junctionAlias)) {
            myTarget.hasMany($junctionAlias, [
                "targetTable":$junction,
                "bindingKey":myTargetBindingKey,
                "foreignKey":this.getTargetForeignKey(),
                "strategy":_strategy,
            ]);
        }
        if (!myTarget.hasAssociation($sAlias)) {
            myTarget.belongsToMany($sAlias, [
                "sourceTable":myTarget,
                "targetTable":$source,
                "foreignKey":this.getTargetForeignKey(),
                "targetForeignKey":this.getForeignKey(),
                "through":$junction,
                "conditions":this.getConditions(),
                "strategy":_strategy,
            ]);
        }
    }

    /**
     * Generate additional source table associations as necessary.
     *
     * Generates the following associations:
     *
     * - source hasMany junction e.g. Tags hasMany ArticlesTags
     *
     * You can override these generated associations by defining associations
     * with the correct aliases.
     *
     * @param uim.cake.ORM\Table $junction The junction table.
     * @param uim.cake.ORM\Table $source The source table.
     * @return void
     */
    protected void _generateSourceAssociations(Table $junction, Table $source) {
        $junctionAlias = $junction.getAlias();
        $sAlias = $source.getAlias();

        $sourceBindingKey = null;
        if ($junction.hasAssociation($sAlias)) {
            $sourceBindingKey = $junction.getAssociation($sAlias).getBindingKey();
        }

        if (!$source.hasAssociation($junctionAlias)) {
            $source.hasMany($junctionAlias, [
                "targetTable":$junction,
                "bindingKey":$sourceBindingKey,
                "foreignKey":this.getForeignKey(),
                "strategy":_strategy,
            ]);
        }
    }

    /**
     * Generate associations on the junction table as necessary
     *
     * Generates the following associations:
     *
     * - junction belongsTo source e.g. ArticlesTags belongsTo Tags
     * - junction belongsTo target e.g. ArticlesTags belongsTo Articles
     *
     * You can override these generated associations by defining associations
     * with the correct aliases.
     *
     * @param uim.cake.ORM\Table $junction The junction table.
     * @param uim.cake.ORM\Table $source The source table.
     * @param uim.cake.ORM\Table myTarget The target table.
     * @return void
     * @throws \InvalidArgumentException If the expected associations are incompatible with existing associations.
     */
    protected void _generateJunctionAssociations(Table $junction, Table $source, Table myTarget) {
        $tAlias = myTarget.getAlias();
        $sAlias = $source.getAlias();

        if (!$junction.hasAssociation($tAlias)) {
            $junction.belongsTo($tAlias, [
                "foreignKey":this.getTargetForeignKey(),
                "targetTable":myTarget,
            ]);
        } else {
            $belongsTo = $junction.getAssociation($tAlias);
            if (
                this.getTargetForeignKey() != $belongsTo.getForeignKey() ||
                myTarget != $belongsTo.getTarget()
            ) {
                throw new InvalidArgumentException(
                    "The existing `{$tAlias}` association on `{$junction.getAlias()}` " .
                    "is incompatible with the `{this.getName()}` association on `{$source.getAlias()}`"
                );
            }
        }

        if (!$junction.hasAssociation($sAlias)) {
            $junction.belongsTo($sAlias, [
                "foreignKey":this.getForeignKey(),
                "targetTable":$source,
            ]);
        }
    }

    /**
     * Alters a Query object to include the associated target table data in the final
     * result
     *
     * The options array accept the following keys:
     *
     * - includeFields: Whether to include target model fields in the result or not
     * - foreignKey: The name of the field to use as foreign key, if false none
     *   will be used
     * - conditions: array with a list of conditions to filter the join with
     * - fields: a list of fields in the target table to include in the result
     * - type: The type of join to be used (e.g. INNER)
     *
     * @param uim.cake.ORM\Query myQuery the query to be altered to include the target table data
     * @param array<string, mixed> myOptions Any extra options or overrides to be taken in account
     * @return void
     */
    void attachTo(Query myQuery, array myOptions = []) {
        if (!empty(myOptions["negateMatch"])) {
            _appendNotMatching(myQuery, myOptions);

            return;
        }

        $junction = this.junction();
        $belongsTo = $junction.getAssociation(this.getSource().getAlias());
        $cond = $belongsTo._joinCondition(["foreignKey":$belongsTo.getForeignKey()]);
        $cond += this.junctionConditions();

        $includeFields = myOptions["includeFields"] ?? null;

        // Attach the junction table as well we need it to populate _joinData.
        $assoc = _targetTable.getAssociation($junction.getAlias());
        $newOptions = array_intersect_key(myOptions, ["joinType":1, "fields":1]);
        $newOptions += [
            "conditions":$cond,
            "includeFields":$includeFields,
            "foreignKey":false,
        ];
        $assoc.attachTo(myQuery, $newOptions);
        myQuery.getEagerLoader().addToJoinsMap($junction.getAlias(), $assoc, true);

        super.attachTo(myQuery, myOptions);

        $foreignKey = this.getTargetForeignKey();
        thisJoin = myQuery.clause("join")[this.getName()];
        thisJoin["conditions"].add($assoc._joinCondition(["foreignKey":$foreignKey]));
    }


    protected void _appendNotMatching(Query myQuery, array myOptions) {
        if (empty(myOptions["negateMatch"])) {
            return;
        }
        myOptions["conditions"] = myOptions["conditions"] ?? [];
        $junction = this.junction();
        $belongsTo = $junction.getAssociation(this.getSource().getAlias());
        $conds = $belongsTo._joinCondition(["foreignKey":$belongsTo.getForeignKey()]);

        $subquery = this.find()
            .select(array_values($conds))
            .where(myOptions["conditions"]);

        if (!empty(myOptions["queryBuilder"])) {
            $subquery = myOptions["queryBuilder"]($subquery);
        }

        $subquery = _appendJunctionJoin($subquery);

        myQuery
            .andWhere(function (QueryExpression $exp) use ($subquery, $conds) {
                myIdentifiers = [];
                foreach (array_keys($conds) as myField) {
                    myIdentifiers[] = new IdentifierExpression(myField);
                }
                myIdentifiers = $subquery.newExpr().add(myIdentifiers).setConjunction(",");
                $nullExp = clone $exp;

                return $exp
                    .or([
                        $exp.notIn(myIdentifiers, $subquery),
                        $nullExp.and(array_map([$nullExp, "isNull"], array_keys($conds))),
                    ]);
            });
    }

    /**
     * Get the relationship type.
     */
    string type() {
        return self::MANY_TO_MANY;
    }

    /**
     * Return false as join conditions are defined in the junction table
     *
     * @param array<string, mixed> myOptions list of options passed to attachTo method
     * @return array
     */
    protected auto _joinCondition(array myOptions): array
    {
        return [];
    }


    Closure eagerLoader(array myOptions) {
        myName = _junctionAssociationName();
        $loader = new SelectWithPivotLoader([
            "alias":this.getAlias(),
            "sourceAlias":this.getSource().getAlias(),
            "targetAlias":this.getTarget().getAlias(),
            "foreignKey":this.getForeignKey(),
            "bindingKey":this.getBindingKey(),
            "strategy":this.getStrategy(),
            "associationType":this.type(),
            "sort":this.getSort(),
            "junctionAssociationName":myName,
            "junctionProperty":_junctionProperty,
            "junctionAssoc":this.getTarget().getAssociation(myName),
            "junctionConditions":this.junctionConditions(),
            "finder":function () {
                return _appendJunctionJoin(this.find(), []);
            },
        ]);

        return $loader.buildEagerLoader(myOptions);
    }

    /**
     * Clear out the data in the junction table for a given entity.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity that started the cascading delete.
     * @param array<string, mixed> myOptions The options for the original delete.
     * @return bool Success.
     */
    bool cascadeDelete(IEntity $entity, array myOptions = []) {
        if (!this.getDependent()) {
            return true;
        }
        $foreignKey = (array)this.getForeignKey();
        $bindingKey = (array)this.getBindingKey();
        $conditions = [];

        if (!empty($bindingKey)) {
            $conditions = array_combine($foreignKey, $entity.extract($bindingKey));
        }

        myTable = this.junction();
        $hasMany = this.getSource().getAssociation(myTable.getAlias());
        if (_cascadeCallbacks) {
            foreach ($hasMany.find("all").where($conditions).all().toList() as $related) {
                $success = myTable.delete($related, myOptions);
                if (!$success) {
                    return false;
                }
            }

            return true;
        }

        $assocConditions = $hasMany.getConditions();
        if (is_array($assocConditions)) {
            $conditions = array_merge($conditions, $assocConditions);
        } else {
            $conditions[] = $assocConditions;
        }

        myTable.deleteAll($conditions);

        return true;
    }

    /**
     * Returns boolean true, as both of the tables "own" rows in the other side
     * of the association via the joint table.
     *
     * @param uim.cake.ORM\Table $side The potential Table with ownership
     */
    bool isOwningSide(Table $side) {
        return true;
    }

    /**
     * Sets the strategy that should be used for saving.
     *
     * @param string strategy the strategy name to be used
     * @throws \InvalidArgumentException if an invalid strategy name is passed
     * @return this
     */
    auto setSaveStrategy(string strategy) {
        if (!in_array($strategy, [self::SAVE_APPEND, self::SAVE_REPLACE], true)) {
            $msg = sprintf("Invalid save strategy "%s"", $strategy);
            throw new InvalidArgumentException($msg);
        }

        _saveStrategy = $strategy;

        return this;
    }

    /**
     * Gets the strategy that should be used for saving.
     *
     * @return string the strategy to be used for saving
     */
    string getSaveStrategy() {
        return _saveStrategy;
    }

    /**
     * Takes an entity from the source table and looks if there is a field
     * matching the property name for this association. The found entity will be
     * saved on the target table for this association by passing supplied
     * `myOptions`
     *
     * When using the "append" strategy, this function will only create new links
     * between each side of this association. It will not destroy existing ones even
     * though they may not be present in the array of entities to be saved.
     *
     * When using the "replace" strategy, existing links will be removed and new links
     * will be created in the joint table. If there exists links in the database to some
     * of the entities intended to be saved by this method, they will be updated,
     * not deleted.
     *
     * @param uim.cake.Datasource\IEntity $entity an entity from the source table
     * @param array<string, mixed> myOptions options to be passed to the save method in the target table
     * @throws \InvalidArgumentException if the property representing the association
     * in the parent entity cannot be traversed
     * @return uim.cake.Datasource\IEntity|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see uim.cake.ORM\Table::save()
     * @see uim.cake.ORM\Association\BelongsToMany::replaceLinks()
     */
    function saveAssociated(IEntity $entity, array myOptions = []) {
        myTargetEntity = $entity.get(this.getProperty());
        $strategy = this.getSaveStrategy();

        $isEmpty = in_array(myTargetEntity, [null, [], "", false], true);
        if ($isEmpty && $entity.isNew()) {
            return $entity;
        }
        if ($isEmpty) {
            myTargetEntity = [];
        }

        if ($strategy == self::SAVE_APPEND) {
            return _saveTarget($entity, myTargetEntity, myOptions);
        }

        if (this.replaceLinks($entity, myTargetEntity, myOptions)) {
            return $entity;
        }

        return false;
    }

    /**
     * Persists each of the entities into the target table and creates links between
     * the parent entity and each one of the saved target entities.
     *
     * @param uim.cake.Datasource\IEntity $parentEntity the source entity containing the target
     * entities to be saved.
     * @param array $entities list of entities to persist in target table and to
     * link to the parent entity
     * @param array<string, mixed> myOptions list of options accepted by `Table::save()`
     * @throws \InvalidArgumentException if the property representing the association
     * in the parent entity cannot be traversed
     * @return uim.cake.Datasource\IEntity|false The parent entity after all links have been
     * created if no errors happened, false otherwise
     */
    protected auto _saveTarget(IEntity $parentEntity, array $entities, myOptions) {
        $joinAssociations = false;
        if (isset(myOptions["associated"]) && is_array(myOptions["associated"])) {
            if (!empty(myOptions["associated"][_junctionProperty]["associated"])) {
                $joinAssociations = myOptions["associated"][_junctionProperty]["associated"];
            }
            unset(myOptions["associated"][_junctionProperty]);
        }

        myTable = this.getTarget();
        $original = $entities;
        $persisted = [];

        foreach ($entities as $k: $entity) {
            if (!($entity instanceof IEntity)) {
                break;
            }

            if (!empty(myOptions["atomic"])) {
                $entity = clone $entity;
            }

            $saved = myTable.save($entity, myOptions);
            if ($saved) {
                $entities[$k] = $entity;
                $persisted[] = $entity;
                continue;
            }

            // Saving the new linked entity failed, copy errors back into the
            // original entity if applicable and abort.
            if (!empty(myOptions["atomic"])) {
                $original[$k].setErrors($entity.getErrors());
            }
            if ($saved == false) {
                return false;
            }
        }

        myOptions["associated"] = $joinAssociations;
        $success = _saveLinks($parentEntity, $persisted, myOptions);
        if (!$success && !empty(myOptions["atomic"])) {
            $parentEntity.set(this.getProperty(), $original);

            return false;
        }

        $parentEntity.set(this.getProperty(), $entities);

        return $parentEntity;
    }

    /**
     * Creates links between the source entity and each of the passed target entities
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity the entity from source table in this
     * association
     * @param array<\Cake\Datasource\IEntity> myTargetEntities list of entities to link to link to the source entity using the
     * junction table
     * @param array<string, mixed> myOptions list of options accepted by `Table::save()`
     * @return bool success
     */
    protected bool _saveLinks(IEntity $sourceEntity, array myTargetEntities, array myOptions) {
        myTarget = this.getTarget();
        $junction = this.junction();
        $entityClass = $junction.getEntityClass();
        $belongsTo = $junction.getAssociation(myTarget.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $assocForeignKey = (array)$belongsTo.getForeignKey();
        myTargetBindingKey = (array)$belongsTo.getBindingKey();
        $bindingKey = (array)this.getBindingKey();
        $jointProperty = _junctionProperty;
        $junctionRegistryAlias = $junction.getRegistryAlias();

        foreach (myTargetEntities as $e) {
            $joint = $e.get($jointProperty);
            if (!$joint || !($joint instanceof IEntity)) {
                $joint = new $entityClass([], ["markNew":true, "source":$junctionRegistryAlias]);
            }
            $sourceKeys = array_combine($foreignKey, $sourceEntity.extract($bindingKey));
            myTargetKeys = array_combine($assocForeignKey, $e.extract(myTargetBindingKey));

            $changedKeys = (
                $sourceKeys != $joint.extract($foreignKey) ||
                myTargetKeys != $joint.extract($assocForeignKey)
            );
            // Keys were changed, the junction table record _could_ be
            // new. By clearing the primary key values, and marking the entity
            // as new, we let save() sort out whether we have a new link
            // or if we are updating an existing link.
            if ($changedKeys) {
                $joint.setNew(true);
                $joint.unset($junction.getPrimaryKey())
                    .set(array_merge($sourceKeys, myTargetKeys), ["guard":false]);
            }
            $saved = $junction.save($joint, myOptions);

            if (!$saved && !empty(myOptions["atomic"])) {
                return false;
            }

            $e.set($jointProperty, $joint);
            $e.setDirty($jointProperty, false);
        }

        return true;
    }

    /**
     * Associates the source entity to each of the target entities provided by
     * creating links in the junction table. Both the source entity and each of
     * the target entities are assumed to be already persisted, if they are marked
     * as new or their status is unknown then an exception will be thrown.
     *
     * When using this method, all entities in `myTargetEntities` will be appended to
     * the source entity"s property corresponding to this association object.
     *
     * This method does not check link uniqueness.
     *
     * ### Example:
     *
     * ```
     * $newTags = $tags.find("relevant").toArray();
     * $articles.getAssociation("tags").link($article, $newTags);
     * ```
     *
     * `$article.get("tags")` will contain all tags in `$newTags` after liking
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity the row belonging to the `source` side
     *   of this association
     * @param array<\Cake\Datasource\IEntity> myTargetEntities list of entities belonging to the `target` side
     *   of this association
     * @param array<string, mixed> myOptions list of options to be passed to the internal `save` call
     * @throws \InvalidArgumentException when any of the values in myTargetEntities is
     *   detected to not be already persisted
     * @return bool true on success, false otherwise
     */
    bool link(IEntity $sourceEntity, array myTargetEntities, array myOptions = []) {
        _checkPersistenceStatus($sourceEntity, myTargetEntities);
        $property = this.getProperty();
        $links = $sourceEntity.get($property) ?: [];
        $links = array_merge($links, myTargetEntities);
        $sourceEntity.set($property, $links);

        return this.junction().getConnection().transactional(
            function () use ($sourceEntity, myTargetEntities, myOptions) {
                return _saveLinks($sourceEntity, myTargetEntities, myOptions);
            }
        );
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
     * ### Example:
     *
     * ```
     * $article.tags = [$tag1, $tag2, $tag3, $tag4];
     * $tags = [$tag1, $tag2, $tag3];
     * $articles.getAssociation("tags").unlink($article, $tags);
     * ```
     *
     * `$article.get("tags")` will contain only `[$tag4]` after deleting in the database
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity An entity persisted in the source table for
     *   this association.
     * @param array<\Cake\Datasource\IEntity> myTargetEntities List of entities persisted in the target table for
     *   this association.
     * @param array<string>|bool myOptions List of options to be passed to the internal `delete` call,
     *   or a `boolean` as `cleanProperty` key shortcut.
     * @throws \InvalidArgumentException If non persisted entities are passed or if
     *   any of them is lacking a primary key value.
     * @return bool Success
     */
    bool unlink(IEntity $sourceEntity, array myTargetEntities, myOptions = []) {
        if (is_bool(myOptions)) {
            myOptions = [
                "cleanProperty":myOptions,
            ];
        } else {
            myOptions += ["cleanProperty":true];
        }

        _checkPersistenceStatus($sourceEntity, myTargetEntities);
        $property = this.getProperty();

        this.junction().getConnection().transactional(
            void () use ($sourceEntity, myTargetEntities, myOptions) {
                $links = _collectJointEntities($sourceEntity, myTargetEntities);
                foreach ($links as $entity) {
                    _junctionTable.delete($entity, myOptions);
                }
            }
        );

        /** @var array<\Cake\Datasource\IEntity> $existing */
        $existing = $sourceEntity.get($property) ?: [];
        if (!myOptions["cleanProperty"] || empty($existing)) {
            return true;
        }

        /** @var \SplObjectStorage<\Cake\Datasource\IEntity, null> $storage */
        $storage = new SplObjectStorage();
        foreach (myTargetEntities as $e) {
            $storage.attach($e);
        }

        foreach ($existing as $k: $e) {
            if ($storage.contains($e)) {
                unset($existing[$k]);
            }
        }

        $sourceEntity.set($property, array_values($existing));
        $sourceEntity.setDirty($property, false);

        return true;
    }


    auto setConditions($conditions) {
        super.setConditions($conditions);
        _targetConditions = _junctionConditions = null;

        return this;
    }

    /**
     * Sets the current join table, either the name of the Table instance or the instance itself.
     *
     * @param uim.cake.ORM\Table|string through Name of the Table instance or the instance itself
     * @return this
     */
    auto setThrough($through) {
        _through = $through;

        return this;
    }

    /**
     * Gets the current join table, either the name of the Table instance or the instance itself.
     *
     * @return uim.cake.ORM\Table|string
     */
    auto getThrough() {
        return _through;
    }

    /**
     * Returns filtered conditions that reference the target table.
     *
     * Any string expressions, or expression objects will
     * also be returned in this list.
     *
     * @return array|\Closure|null Generally an array. If the conditions
     *   are not an array, the association conditions will be
     *   returned unmodified.
     */
    protected auto targetConditions() {
        if (_targetConditions  !is null) {
            return _targetConditions;
        }
        $conditions = this.getConditions();
        if (!is_array($conditions)) {
            return $conditions;
        }
        $matching = [];
        myAlias = this.getAlias() . ".";
        foreach ($conditions as myField: myValue) {
            if (is_string(myField) && indexOf(myField, myAlias) == 0) {
                $matching[myField] = myValue;
            } elseif (is_int(myField) || myValue instanceof IExpression) {
                $matching[myField] = myValue;
            }
        }

        return _targetConditions = $matching;
    }

    /**
     * Returns filtered conditions that specifically reference
     * the junction table.
     *
     * @return array
     */
    protected auto junctionConditions(): array
    {
        if (_junctionConditions  !is null) {
            return _junctionConditions;
        }
        $matching = [];
        $conditions = this.getConditions();
        if (!is_array($conditions)) {
            return $matching;
        }
        myAlias = _junctionAssociationName() . ".";
        foreach ($conditions as myField: myValue) {
            $isString = is_string(myField);
            if ($isString && indexOf(myField, myAlias) == 0) {
                $matching[myField] = myValue;
            }
            // Assume that operators contain junction conditions.
            // Trying to manage complex conditions could result in incorrect queries.
            if ($isString && in_array(strtoupper(myField), ["OR", "NOT", "AND", "XOR"], true)) {
                $matching[myField] = myValue;
            }
        }

        return _junctionConditions = $matching;
    }

    /**
     * Proxies the finding operation to the target table"s find method
     * and modifies the query accordingly based of this association
     * configuration.
     *
     * If your association includes conditions or a finder, the junction table will be
     * included in the query"s contained associations.
     *
     * @param array<string, mixed>|string|null myType the type of query to perform, if an array is passed,
     *   it will be interpreted as the `myOptions` parameter
     * @param array<string, mixed> myOptions The options to for the find
     * @see uim.cake.ORM\Table::find()
     * @return uim.cake.ORM\Query
     */
    function find(myType = null, array myOptions = []): Query
    {
        myType = myType ?: this.getFinder();
        [myType, $opts] = _extractFinder(myType);
        myQuery = this.getTarget()
            .find(myType, myOptions + $opts)
            .where(this.targetConditions())
            .addDefaultTypes(this.getTarget());

        if (this.junctionConditions()) {
            return _appendJunctionJoin(myQuery);
        }

        return myQuery;
    }

    /**
     * Append a join to the junction table.
     *
     * @param uim.cake.ORM\Query myQuery The query to append.
     * @param array|null $conditions The query conditions to use.
     * @return uim.cake.ORM\Query The modified query.
     */
    protected auto _appendJunctionJoin(Query myQuery, ?array $conditions = null): Query
    {
        $junctionTable = this.junction();
        if ($conditions is null) {
            $belongsTo = $junctionTable.getAssociation(this.getTarget().getAlias());
            $conditions = $belongsTo._joinCondition([
                "foreignKey":this.getTargetForeignKey(),
            ]);
            $conditions += this.junctionConditions();
        }

        myName = _junctionAssociationName();
        /** @var array $joins */
        $joins = myQuery.clause("join");
        $matching = [
            myName: [
                "table":$junctionTable.getTable(),
                "conditions":$conditions,
                "type":Query::JOIN_TYPE_INNER,
            ],
        ];

        myQuery
            .addDefaultTypes($junctionTable)
            .join($matching + $joins, [], true);

        return myQuery;
    }

    /**
     * Replaces existing association links between the source entity and the target
     * with the ones passed. This method does a smart cleanup, links that are already
     * persisted and present in `myTargetEntities` will not be deleted, new links will
     * be created for the passed target entities that are not already in the database
     * and the rest will be removed.
     *
     * For example, if an article is linked to tags "cake" and "framework" and you pass
     * to this method an array containing the entities for tags "cake", "php" and "awesome",
     * only the link for cake will be kept in database, the link for "framework" will be
     * deleted and the links for "php" and "awesome" will be created.
     *
     * Existing links are not deleted and created again, they are either left untouched
     * or updated so that potential extra information stored in the joint row is not
     * lost. Updating the link row can be done by making sure the corresponding passed
     * target entity contains the joint property with its primary key and any extra
     * information to be stored.
     *
     * On success, the passed `$sourceEntity` will contain `myTargetEntities` as value
     * in the corresponding property for this association.
     *
     * This method assumes that links between both the source entity and each of the
     * target entities are unique. That is, for any given row in the source table there
     * can only be one link in the junction table pointing to any other given row in
     * the target table.
     *
     * Additional options for new links to be saved can be passed in the third argument,
     * check `Table::save()` for information on the accepted options.
     *
     * ### Example:
     *
     * ```
     * $article.tags = [$tag1, $tag2, $tag3, $tag4];
     * $articles.save($article);
     * $tags = [$tag1, $tag3];
     * $articles.getAssociation("tags").replaceLinks($article, $tags);
     * ```
     *
     * `$article.get("tags")` will contain only `[$tag1, $tag3]` at the end
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity an entity persisted in the source table for
     *   this association
     * @param array myTargetEntities list of entities from the target table to be linked
     * @param array<string, mixed> myOptions list of options to be passed to the internal `save`/`delete` calls
     *   when persisting/updating new links, or deleting existing ones
     * @throws \InvalidArgumentException if non persisted entities are passed or if
     *   any of them is lacking a primary key value
     * @return bool success
     */
    bool replaceLinks(IEntity $sourceEntity, array myTargetEntities, array myOptions = []) {
        $bindingKey = (array)this.getBindingKey();
        $primaryValue = $sourceEntity.extract($bindingKey);

        if (count(Hash::filter($primaryValue)) != count($bindingKey)) {
            myMessage = "Could not find primary key value for source entity";
            throw new InvalidArgumentException(myMessage);
        }

        return this.junction().getConnection().transactional(
            function () use ($sourceEntity, myTargetEntities, $primaryValue, myOptions) {
                $junction = this.junction();
                myTarget = this.getTarget();

                $foreignKey = (array)this.getForeignKey();
                $prefixedForeignKey = array_map([$junction, "aliasField"], $foreignKey);

                $junctionPrimaryKey = (array)$junction.getPrimaryKey();
                $assocForeignKey = (array)$junction.getAssociation(myTarget.getAlias()).getForeignKey();

                myKeys = array_combine($foreignKey, $prefixedForeignKey);
                foreach (array_merge($assocForeignKey, $junctionPrimaryKey) as myKey) {
                    myKeys[myKey] = $junction.aliasField(myKey);
                }

                // Find junction records. We join with the association target so that junction
                // conditions from `targetConditions()` or the finder work.
                $existing = $junction.find()
                    .innerJoinWith(myTarget.getAlias())
                    .where(this.targetConditions())
                    .where(this.junctionConditions())
                    .where(array_combine($prefixedForeignKey, $primaryValue));
                [myFinder, myFinderOptions] = _extractFinder(this.getFinder());
                if (myFinder) {
                    $existing = myTarget.callFinder(myFinder, $existing, myFinderOptions);
                }

                $jointEntities = _collectJointEntities($sourceEntity, myTargetEntities);
                $inserts = _diffLinks($existing, $jointEntities, myTargetEntities, myOptions);
                if ($inserts == false) {
                    return false;
                }

                if ($inserts && !_saveTarget($sourceEntity, $inserts, myOptions)) {
                    return false;
                }

                $property = this.getProperty();

                if (count($inserts)) {
                    $inserted = array_combine(
                        array_keys($inserts),
                        (array)$sourceEntity.get($property)
                    ) ?: [];
                    myTargetEntities = $inserted + myTargetEntities;
                }

                ksort(myTargetEntities);
                $sourceEntity.set($property, array_values(myTargetEntities));
                $sourceEntity.setDirty($property, false);

                return true;
            }
        );
    }

    /**
     * Helper method used to delete the difference between the links passed in
     * `$existing` and `$jointEntities`. This method will return the values from
     * `myTargetEntities` that were not deleted from calculating the difference.
     *
     * @param uim.cake.ORM\Query $existing a query for getting existing links
     * @param array<\Cake\Datasource\IEntity> $jointEntities link entities that should be persisted
     * @param array myTargetEntities entities in target table that are related to
     * the `$jointEntities`
     * @param array<string, mixed> myOptions list of options accepted by `Table::delete()`
     * @return array|false Array of entities not deleted or false in case of deletion failure for atomic saves.
     */
    protected auto _diffLinks(
        Query $existing,
        array $jointEntities,
        array myTargetEntities,
        array myOptions = []
    ) {
        $junction = this.junction();
        myTarget = this.getTarget();
        $belongsTo = $junction.getAssociation(myTarget.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $assocForeignKey = (array)$belongsTo.getForeignKey();

        myKeys = array_merge($foreignKey, $assocForeignKey);
        $deletes = $indexed = $present = [];

        foreach ($jointEntities as $i: $entity) {
            $indexed[$i] = $entity.extract(myKeys);
            $present[$i] = array_values($entity.extract($assocForeignKey));
        }

        foreach ($existing as myResult) {
            myFields = myResult.extract(myKeys);
            $found = false;
            foreach ($indexed as $i: myData) {
                if (myFields == myData) {
                    unset($indexed[$i]);
                    $found = true;
                    break;
                }
            }

            if (!$found) {
                $deletes[] = myResult;
            }
        }

        $primary = (array)myTarget.getPrimaryKey();
        $jointProperty = _junctionProperty;
        foreach (myTargetEntities as $k: $entity) {
            if (!($entity instanceof IEntity)) {
                continue;
            }
            myKey = array_values($entity.extract($primary));
            foreach ($present as $i: myData) {
                if (myKey == myData && !$entity.get($jointProperty)) {
                    unset(myTargetEntities[$k], $present[$i]);
                    break;
                }
            }
        }

        foreach ($deletes as $entity) {
            if (!$junction.delete($entity, myOptions) && !empty(myOptions["atomic"])) {
                return false;
            }
        }

        return myTargetEntities;
    }

    /**
     * Throws an exception should any of the passed entities is not persisted.
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity the row belonging to the `source` side
     *   of this association
     * @param array<\Cake\Datasource\IEntity> myTargetEntities list of entities belonging to the `target` side
     *   of this association
     * @return bool
     * @throws \InvalidArgumentException
     */
    protected bool _checkPersistenceStatus(IEntity $sourceEntity, array myTargetEntities) {
        if ($sourceEntity.isNew()) {
            myError = "Source entity needs to be persisted before links can be created or removed.";
            throw new InvalidArgumentException(myError);
        }

        foreach (myTargetEntities as $entity) {
            if ($entity.isNew()) {
                myError = "Cannot link entities that have not been persisted yet.";
                throw new InvalidArgumentException(myError);
            }
        }

        return true;
    }

    /**
     * Returns the list of joint entities that exist between the source entity
     * and each of the passed target entities
     *
     * @param uim.cake.Datasource\IEntity $sourceEntity The row belonging to the source side
     *   of this association.
     * @param array myTargetEntities The rows belonging to the target side of this
     *   association.
     * @throws \InvalidArgumentException if any of the entities is lacking a primary
     *   key value
     * @return array<\Cake\Datasource\IEntity>
     */
    protected auto _collectJointEntities(IEntity $sourceEntity, array myTargetEntities): array
    {
        myTarget = this.getTarget();
        $source = this.getSource();
        $junction = this.junction();
        $jointProperty = _junctionProperty;
        $primary = (array)myTarget.getPrimaryKey();

        myResult = [];
        $missing = [];

        foreach (myTargetEntities as $entity) {
            if (!($entity instanceof IEntity)) {
                continue;
            }
            $joint = $entity.get($jointProperty);

            if (!$joint || !($joint instanceof IEntity)) {
                $missing[] = $entity.extract($primary);
                continue;
            }

            myResult[] = $joint;
        }

        if (empty($missing)) {
            return myResult;
        }

        $belongsTo = $junction.getAssociation(myTarget.getAlias());
        $hasMany = $source.getAssociation($junction.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $foreignKey = array_map(function (myKey) {
            return myKey . " IS";
        }, $foreignKey);
        $assocForeignKey = (array)$belongsTo.getForeignKey();
        $assocForeignKey = array_map(function (myKey) {
            return myKey . " IS";
        }, $assocForeignKey);
        $sourceKey = $sourceEntity.extract((array)$source.getPrimaryKey());

        $unions = [];
        foreach ($missing as myKey) {
            $unions[] = $hasMany.find()
                .where(array_combine($foreignKey, $sourceKey))
                .where(array_combine($assocForeignKey, myKey));
        }

        myQuery = array_shift($unions);
        foreach ($unions as $q) {
            myQuery.union($q);
        }

        return array_merge(myResult, myQuery.toArray());
    }

    /**
     * Returns the name of the association from the target table to the junction table,
     * this name is used to generate alias in the query and to later on retrieve the
     * results.
     *
     * @return string
     */
    protected string _junctionAssociationName() {
        if (!_junctionAssociationName) {
            _junctionAssociationName = this.getTarget()
                .getAssociation(this.junction().getAlias())
                .getName();
        }

        return _junctionAssociationName;
    }

    /**
     * Sets the name of the junction table.
     * If no arguments are passed the current configured name is returned. A default
     * name based of the associated tables will be generated if none found.
     *
     * @param string|null myName The name of the junction table.
     * @return string
     */
    protected string _junctionTableName(Nullable!string myName = null) {
        if (myName is null) {
            if (empty(_junctionTableName)) {
                myTablesNames = array_map("Cake\Utility\Inflector::underscore", [
                    this.getSource().getTable(),
                    this.getTarget().getTable(),
                ]);
                sort(myTablesNames);
                _junctionTableName = implode("_", myTablesNames);
            }

            return _junctionTableName;
        }

        return _junctionTableName = myName;
    }

    /**
     * Parse extra options passed in the constructor.
     *
     * @param array<string, mixed> myOptions original list of options passed in constructor
     * @return void
     */
    protected void _options(array myOptions) {
        if (!empty(myOptions["targetForeignKey"])) {
            this.setTargetForeignKey(myOptions["targetForeignKey"]);
        }
        if (!empty(myOptions["joinTable"])) {
            _junctionTableName(myOptions["joinTable"]);
        }
        if (!empty(myOptions["through"])) {
            this.setThrough(myOptions["through"]);
        }
        if (!empty(myOptions["saveStrategy"])) {
            this.setSaveStrategy(myOptions["saveStrategy"]);
        }
        if (isset(myOptions["sort"])) {
            this.setSort(myOptions["sort"]);
        }
    }
}
