


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Association;

import uim.cake.cores.App;
import uim.cake.databases.Expression\IdentifierExpression;
import uim.cake.databases.Expression\QueryExpression;
import uim.cake.databases.IExpression;
import uim.cake.Datasource\EntityInterface;
import uim.cake.ORM\Association;
import uim.cake.ORM\Association\Loader\SelectWithPivotLoader;
import uim.cake.ORM\Query;
import uim.cake.ORM\Table;
import uim.cake.Utility\Hash;
import uim.cake.Utility\Inflector;
use Closure;
use InvalidArgumentException;
use SplObjectStorage;

/**
 * Represents an M - N relationship where there exists a junction - or join - table
 * that contains the association fields between the source and the target table.
 *
 * An example of a BelongsToMany association would be Article belongs to many Tags.
 * In this example "Article" is the source table and "Tags" is the target table.
 */
class BelongsToMany : Association
{
    /**
     * Saving strategy that will only append to the links set
     *
     * @var string
     */
    public const SAVE_APPEND = "append";

    /**
     * Saving strategy that will replace the links with the provided set
     *
     * @var string
     */
    public const SAVE_REPLACE = "replace";

    /**
     * The type of join to be used when adding the association to a query
     *
     * @var string
     */
    protected $_joinType = Query::JOIN_TYPE_INNER;

    /**
     * The strategy name to be used to fetch associated records.
     *
     * @var string
     */
    protected $_strategy = self::STRATEGY_SELECT;

    /**
     * Junction table instance
     *
     * @var \Cake\ORM\Table
     */
    protected $_junctionTable;

    /**
     * Junction table name
     *
     * @var string
     */
    protected $_junctionTableName;

    /**
     * The name of the hasMany association from the target table
     * to the junction table
     *
     * @var string
     */
    protected $_junctionAssociationName;

    /**
     * The name of the property to be set containing data from the junction table
     * once a record from the target table is hydrated
     *
     * @var string
     */
    protected $_junctionProperty = "_joinData";

    /**
     * Saving strategy to be used by this association
     *
     * @var string
     */
    protected $_saveStrategy = self::SAVE_REPLACE;

    /**
     * The name of the field representing the foreign key to the target table
     *
     * @var array<string>|string|null
     */
    protected $_targetForeignKey;

    /**
     * The table instance for the junction relation.
     *
     * @var \Cake\ORM\Table|string
     */
    protected $_through;

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
     * Whether the records on the joint table should be removed when a record
     * on the source table is deleted.
     *
     * Defaults to true for backwards compatibility.
     *
     * @var bool
     */
    protected $_dependent = true;

    /**
     * Filtered conditions that reference the target table.
     *
     * @var array|null
     */
    protected $_targetConditions;

    /**
     * Filtered conditions that reference the junction table.
     *
     * @var array|null
     */
    protected $_junctionConditions;

    /**
     * Order in which target records should be returned
     *
     * @var mixed
     */
    protected $_sort;

    /**
     * Sets the name of the field representing the foreign key to the target table.
     *
     * @param array<string>|string $key the key to be used to link both tables together
     * @return this
     */
    function setTargetForeignKey($key)
    {
        _targetForeignKey = $key;

        return this;
    }

    /**
     * Gets the name of the field representing the foreign key to the target table.
     *
     * @return array<string>|string
     */
    string[] getTargetForeignKey()
    {
        if (_targetForeignKey == null) {
            _targetForeignKey = _modelKey(this.getTarget().getAlias());
        }

        return _targetForeignKey;
    }

    /**
     * Whether this association can be expressed directly in a query join
     *
     * @param array<string, mixed> $options custom options key that could alter the return value
     * @return bool if the "matching" key in $option is true then this function
     * will return true, false otherwise
     */
    function canBeJoined(array $options = []): bool
    {
        return !empty($options["matching"]);
    }

    /**
     * Gets the name of the field representing the foreign key to the source table.
     *
     * @return array<string>|string
     */
    string[] getForeignKey()
    {
        if (_foreignKey == null) {
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
    function setSort($sort)
    {
        _sort = $sort;

        return this;
    }

    /**
     * Gets the sort order in which target records should be returned.
     *
     * @return mixed
     */
    function getSort()
    {
        return _sort;
    }

    /**
     * @inheritDoc
     */
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
     * @param \Cake\ORM\Table|string|null $table Name or instance for the join table
     * @return \Cake\ORM\Table
     * @throws \InvalidArgumentException If the expected associations are incompatible with existing associations.
     */
    function junction($table = null): Table
    {
        if ($table == null && _junctionTable != null) {
            return _junctionTable;
        }

        $tableLocator = this.getTableLocator();
        if ($table == null && _through) {
            $table = _through;
        } elseif ($table == null) {
            $tableName = _junctionTableName();
            $tableAlias = Inflector::camelize($tableName);

            $config = [];
            if (!$tableLocator.exists($tableAlias)) {
                $config = ["table": $tableName, "allowFallbackClass": true];

                // Propagate the connection if we"ll get an auto-model
                if (!App::className($tableAlias, "Model/Table", "Table")) {
                    $config["connection"] = this.getSource().getConnection();
                }
            }
            $table = $tableLocator.get($tableAlias, $config);
        }

        if (is_string($table)) {
            $table = $tableLocator.get($table);
        }

        $source = this.getSource();
        $target = this.getTarget();
        if ($source.getAlias() == $target.getAlias()) {
            throw new InvalidArgumentException(sprintf(
                "The `%s` association on `%s` cannot target the same table.",
                this.getName(),
                $source.getAlias()
            ));
        }

        _generateSourceAssociations($table, $source);
        _generateTargetAssociations($table, $source, $target);
        _generateJunctionAssociations($table, $source, $target);

        return _junctionTable = $table;
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
     * @param \Cake\ORM\Table $junction The junction table.
     * @param \Cake\ORM\Table $source The source table.
     * @param \Cake\ORM\Table $target The target table.
     * @return void
     */
    protected function _generateTargetAssociations(Table $junction, Table $source, Table $target): void
    {
        $junctionAlias = $junction.getAlias();
        $sAlias = $source.getAlias();
        $tAlias = $target.getAlias();

        $targetBindingKey = null;
        if ($junction.hasAssociation($tAlias)) {
            $targetBindingKey = $junction.getAssociation($tAlias).getBindingKey();
        }

        if (!$target.hasAssociation($junctionAlias)) {
            $target.hasMany($junctionAlias, [
                "targetTable": $junction,
                "bindingKey": $targetBindingKey,
                "foreignKey": this.getTargetForeignKey(),
                "strategy": _strategy,
            ]);
        }
        if (!$target.hasAssociation($sAlias)) {
            $target.belongsToMany($sAlias, [
                "sourceTable": $target,
                "targetTable": $source,
                "foreignKey": this.getTargetForeignKey(),
                "targetForeignKey": this.getForeignKey(),
                "through": $junction,
                "conditions": this.getConditions(),
                "strategy": _strategy,
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
     * @param \Cake\ORM\Table $junction The junction table.
     * @param \Cake\ORM\Table $source The source table.
     * @return void
     */
    protected function _generateSourceAssociations(Table $junction, Table $source): void
    {
        $junctionAlias = $junction.getAlias();
        $sAlias = $source.getAlias();

        $sourceBindingKey = null;
        if ($junction.hasAssociation($sAlias)) {
            $sourceBindingKey = $junction.getAssociation($sAlias).getBindingKey();
        }

        if (!$source.hasAssociation($junctionAlias)) {
            $source.hasMany($junctionAlias, [
                "targetTable": $junction,
                "bindingKey": $sourceBindingKey,
                "foreignKey": this.getForeignKey(),
                "strategy": _strategy,
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
     * @param \Cake\ORM\Table $junction The junction table.
     * @param \Cake\ORM\Table $source The source table.
     * @param \Cake\ORM\Table $target The target table.
     * @return void
     * @throws \InvalidArgumentException If the expected associations are incompatible with existing associations.
     */
    protected function _generateJunctionAssociations(Table $junction, Table $source, Table $target): void
    {
        $tAlias = $target.getAlias();
        $sAlias = $source.getAlias();

        if (!$junction.hasAssociation($tAlias)) {
            $junction.belongsTo($tAlias, [
                "foreignKey": this.getTargetForeignKey(),
                "targetTable": $target,
            ]);
        } else {
            $belongsTo = $junction.getAssociation($tAlias);
            if (
                this.getTargetForeignKey() != $belongsTo.getForeignKey() ||
                $target != $belongsTo.getTarget()
            ) {
                throw new InvalidArgumentException(
                    "The existing `{$tAlias}` association on `{$junction.getAlias()}` " .
                    "is incompatible with the `{this.getName()}` association on `{$source.getAlias()}`"
                );
            }
        }

        if (!$junction.hasAssociation($sAlias)) {
            $junction.belongsTo($sAlias, [
                "bindingKey": this.getBindingKey(),
                "foreignKey": this.getForeignKey(),
                "targetTable": $source,
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
     * @param \Cake\ORM\Query $query the query to be altered to include the target table data
     * @param array<string, mixed> $options Any extra options or overrides to be taken in account
     * @return void
     */
    function attachTo(Query $query, array $options = []): void
    {
        if (!empty($options["negateMatch"])) {
            _appendNotMatching($query, $options);

            return;
        }

        $junction = this.junction();
        $belongsTo = $junction.getAssociation(this.getSource().getAlias());
        $cond = $belongsTo._joinCondition(["foreignKey": $belongsTo.getForeignKey()]);
        $cond += this.junctionConditions();

        $includeFields = $options["includeFields"] ?? null;

        // Attach the junction table as well we need it to populate _joinData.
        $assoc = _targetTable.getAssociation($junction.getAlias());
        $newOptions = array_intersect_key($options, ["joinType": 1, "fields": 1]);
        $newOptions += [
            "conditions": $cond,
            "includeFields": $includeFields,
            "foreignKey": false,
        ];
        $assoc.attachTo($query, $newOptions);
        $query.getEagerLoader().addToJoinsMap($junction.getAlias(), $assoc, true);

        parent::attachTo($query, $options);

        $foreignKey = this.getTargetForeignKey();
        thisJoin = $query.clause("join")[this.getName()];
        thisJoin["conditions"].add($assoc._joinCondition(["foreignKey": $foreignKey]));
    }

    /**
     * @inheritDoc
     */
    protected function _appendNotMatching(Query $query, array $options): void
    {
        if (empty($options["negateMatch"])) {
            return;
        }
        $options["conditions"] = $options["conditions"] ?? [];
        $junction = this.junction();
        $belongsTo = $junction.getAssociation(this.getSource().getAlias());
        $conds = $belongsTo._joinCondition(["foreignKey": $belongsTo.getForeignKey()]);

        $subquery = this.find()
            .select(array_values($conds))
            .where($options["conditions"]);

        if (!empty($options["queryBuilder"])) {
            $subquery = $options["queryBuilder"]($subquery);
        }

        $subquery = _appendJunctionJoin($subquery);

        $query
            .andWhere(function (QueryExpression $exp) use ($subquery, $conds) {
                $identifiers = [];
                foreach (array_keys($conds) as $field) {
                    $identifiers[] = new IdentifierExpression($field);
                }
                $identifiers = $subquery.newExpr().add($identifiers).setConjunction(",");
                $nullExp = clone $exp;

                return $exp
                    .or([
                        $exp.notIn($identifiers, $subquery),
                        $nullExp.and(array_map([$nullExp, "isNull"], array_keys($conds))),
                    ]);
            });
    }

    /**
     * Get the relationship type.
     *
     * @return string
     */
    function type(): string
    {
        return self::MANY_TO_MANY;
    }

    /**
     * Return false as join conditions are defined in the junction table
     *
     * @param array<string, mixed> $options list of options passed to attachTo method
     * @return array
     */
    protected function _joinCondition(array $options): array
    {
        return [];
    }

    /**
     * @inheritDoc
     */
    function eagerLoader(array $options): Closure
    {
        $name = _junctionAssociationName();
        $loader = new SelectWithPivotLoader([
            "alias": this.getAlias(),
            "sourceAlias": this.getSource().getAlias(),
            "targetAlias": this.getTarget().getAlias(),
            "foreignKey": this.getForeignKey(),
            "bindingKey": this.getBindingKey(),
            "strategy": this.getStrategy(),
            "associationType": this.type(),
            "sort": this.getSort(),
            "junctionAssociationName": $name,
            "junctionProperty": _junctionProperty,
            "junctionAssoc": this.getTarget().getAssociation($name),
            "junctionConditions": this.junctionConditions(),
            "finder": function () {
                return _appendJunctionJoin(this.find(), []);
            },
        ]);

        return $loader.buildEagerLoader($options);
    }

    /**
     * Clear out the data in the junction table for a given entity.
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity that started the cascading delete.
     * @param array<string, mixed> $options The options for the original delete.
     * @return bool Success.
     */
    function cascadeDelete(EntityInterface $entity, array $options = []): bool
    {
        if (!this.getDependent()) {
            return true;
        }
        $foreignKey = (array)this.getForeignKey();
        $bindingKey = (array)this.getBindingKey();
        $conditions = [];

        if (!empty($bindingKey)) {
            $conditions = array_combine($foreignKey, $entity.extract($bindingKey));
        }

        $table = this.junction();
        $hasMany = this.getSource().getAssociation($table.getAlias());
        if (_cascadeCallbacks) {
            foreach ($hasMany.find("all").where($conditions).all().toList() as $related) {
                $success = $table.delete($related, $options);
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

        $table.deleteAll($conditions);

        return true;
    }

    /**
     * Returns boolean true, as both of the tables "own" rows in the other side
     * of the association via the joint table.
     *
     * @param \Cake\ORM\Table $side The potential Table with ownership
     * @return bool
     */
    function isOwningSide(Table $side): bool
    {
        return true;
    }

    /**
     * Sets the strategy that should be used for saving.
     *
     * @param string $strategy the strategy name to be used
     * @throws \InvalidArgumentException if an invalid strategy name is passed
     * @return this
     */
    function setSaveStrategy(string $strategy)
    {
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
    function getSaveStrategy(): string
    {
        return _saveStrategy;
    }

    /**
     * Takes an entity from the source table and looks if there is a field
     * matching the property name for this association. The found entity will be
     * saved on the target table for this association by passing supplied
     * `$options`
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
     * @param \Cake\Datasource\EntityInterface $entity an entity from the source table
     * @param array<string, mixed> $options options to be passed to the save method in the target table
     * @throws \InvalidArgumentException if the property representing the association
     * in the parent entity cannot be traversed
     * @return \Cake\Datasource\EntityInterface|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see \Cake\ORM\Table::save()
     * @see \Cake\ORM\Association\BelongsToMany::replaceLinks()
     */
    function saveAssociated(EntityInterface $entity, array $options = [])
    {
        $targetEntity = $entity.get(this.getProperty());
        $strategy = this.getSaveStrategy();

        $isEmpty = in_array($targetEntity, [null, [], "", false], true);
        if ($isEmpty && $entity.isNew()) {
            return $entity;
        }
        if ($isEmpty) {
            $targetEntity = [];
        }

        if ($strategy == self::SAVE_APPEND) {
            return _saveTarget($entity, $targetEntity, $options);
        }

        if (this.replaceLinks($entity, $targetEntity, $options)) {
            return $entity;
        }

        return false;
    }

    /**
     * Persists each of the entities into the target table and creates links between
     * the parent entity and each one of the saved target entities.
     *
     * @param \Cake\Datasource\EntityInterface $parentEntity the source entity containing the target
     * entities to be saved.
     * @param array $entities list of entities to persist in target table and to
     * link to the parent entity
     * @param array<string, mixed> $options list of options accepted by `Table::save()`
     * @throws \InvalidArgumentException if the property representing the association
     * in the parent entity cannot be traversed
     * @return \Cake\Datasource\EntityInterface|false The parent entity after all links have been
     * created if no errors happened, false otherwise
     */
    protected function _saveTarget(EntityInterface $parentEntity, array $entities, $options)
    {
        $joinAssociations = false;
        if (isset($options["associated"]) && is_array($options["associated"])) {
            if (!empty($options["associated"][_junctionProperty]["associated"])) {
                $joinAssociations = $options["associated"][_junctionProperty]["associated"];
            }
            unset($options["associated"][_junctionProperty]);
        }

        $table = this.getTarget();
        $original = $entities;
        $persisted = [];

        foreach ($entities as $k: $entity) {
            if (!($entity instanceof EntityInterface)) {
                break;
            }

            if (!empty($options["atomic"])) {
                $entity = clone $entity;
            }

            $saved = $table.save($entity, $options);
            if ($saved) {
                $entities[$k] = $entity;
                $persisted[] = $entity;
                continue;
            }

            // Saving the new linked entity failed, copy errors back into the
            // original entity if applicable and abort.
            if (!empty($options["atomic"])) {
                $original[$k].setErrors($entity.getErrors());
            }
            if ($saved == false) {
                return false;
            }
        }

        $options["associated"] = $joinAssociations;
        $success = _saveLinks($parentEntity, $persisted, $options);
        if (!$success && !empty($options["atomic"])) {
            $parentEntity.set(this.getProperty(), $original);

            return false;
        }

        $parentEntity.set(this.getProperty(), $entities);

        return $parentEntity;
    }

    /**
     * Creates links between the source entity and each of the passed target entities
     *
     * @param \Cake\Datasource\EntityInterface $sourceEntity the entity from source table in this
     * association
     * @param array<\Cake\Datasource\EntityInterface> $targetEntities list of entities to link to link to the source entity using the
     * junction table
     * @param array<string, mixed> $options list of options accepted by `Table::save()`
     * @return bool success
     */
    protected function _saveLinks(EntityInterface $sourceEntity, array $targetEntities, array $options): bool
    {
        $target = this.getTarget();
        $junction = this.junction();
        $entityClass = $junction.getEntityClass();
        $belongsTo = $junction.getAssociation($target.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $assocForeignKey = (array)$belongsTo.getForeignKey();
        $targetBindingKey = (array)$belongsTo.getBindingKey();
        $bindingKey = (array)this.getBindingKey();
        $jointProperty = _junctionProperty;
        $junctionRegistryAlias = $junction.getRegistryAlias();

        foreach ($targetEntities as $e) {
            $joint = $e.get($jointProperty);
            if (!$joint || !($joint instanceof EntityInterface)) {
                $joint = new $entityClass([], ["markNew": true, "source": $junctionRegistryAlias]);
            }
            $sourceKeys = array_combine($foreignKey, $sourceEntity.extract($bindingKey));
            $targetKeys = array_combine($assocForeignKey, $e.extract($targetBindingKey));

            $changedKeys = (
                $sourceKeys != $joint.extract($foreignKey) ||
                $targetKeys != $joint.extract($assocForeignKey)
            );
            // Keys were changed, the junction table record _could_ be
            // new. By clearing the primary key values, and marking the entity
            // as new, we let save() sort out whether we have a new link
            // or if we are updating an existing link.
            if ($changedKeys) {
                $joint.setNew(true);
                $joint.unset($junction.getPrimaryKey())
                    .set(array_merge($sourceKeys, $targetKeys), ["guard": false]);
            }
            $saved = $junction.save($joint, $options);

            if (!$saved && !empty($options["atomic"])) {
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
     * When using this method, all entities in `$targetEntities` will be appended to
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
     * @param \Cake\Datasource\EntityInterface $sourceEntity the row belonging to the `source` side
     *   of this association
     * @param array<\Cake\Datasource\EntityInterface> $targetEntities list of entities belonging to the `target` side
     *   of this association
     * @param array<string, mixed> $options list of options to be passed to the internal `save` call
     * @throws \InvalidArgumentException when any of the values in $targetEntities is
     *   detected to not be already persisted
     * @return bool true on success, false otherwise
     */
    function link(EntityInterface $sourceEntity, array $targetEntities, array $options = []): bool
    {
        _checkPersistenceStatus($sourceEntity, $targetEntities);
        $property = this.getProperty();
        $links = $sourceEntity.get($property) ?: [];
        $links = array_merge($links, $targetEntities);
        $sourceEntity.set($property, $links);

        return this.junction().getConnection().transactional(
            function () use ($sourceEntity, $targetEntities, $options) {
                return _saveLinks($sourceEntity, $targetEntities, $options);
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
     * - cleanProperty: Whether to remove all the objects in `$targetEntities` that
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
     * @param \Cake\Datasource\EntityInterface $sourceEntity An entity persisted in the source table for
     *   this association.
     * @param array<\Cake\Datasource\EntityInterface> $targetEntities List of entities persisted in the target table for
     *   this association.
     * @param array<string>|bool $options List of options to be passed to the internal `delete` call,
     *   or a `boolean` as `cleanProperty` key shortcut.
     * @throws \InvalidArgumentException If non persisted entities are passed or if
     *   any of them is lacking a primary key value.
     * @return bool Success
     */
    function unlink(EntityInterface $sourceEntity, array $targetEntities, $options = []): bool
    {
        if (is_bool($options)) {
            $options = [
                "cleanProperty": $options,
            ];
        } else {
            $options += ["cleanProperty": true];
        }

        _checkPersistenceStatus($sourceEntity, $targetEntities);
        $property = this.getProperty();

        this.junction().getConnection().transactional(
            function () use ($sourceEntity, $targetEntities, $options): void {
                $links = _collectJointEntities($sourceEntity, $targetEntities);
                foreach ($links as $entity) {
                    _junctionTable.delete($entity, $options);
                }
            }
        );

        /** @var array<\Cake\Datasource\EntityInterface> $existing */
        $existing = $sourceEntity.get($property) ?: [];
        if (!$options["cleanProperty"] || empty($existing)) {
            return true;
        }

        /** @var \SplObjectStorage<\Cake\Datasource\EntityInterface, null> $storage */
        $storage = new SplObjectStorage();
        foreach ($targetEntities as $e) {
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

    /**
     * @inheritDoc
     */
    function setConditions($conditions)
    {
        parent::setConditions($conditions);
        _targetConditions = _junctionConditions = null;

        return this;
    }

    /**
     * Sets the current join table, either the name of the Table instance or the instance itself.
     *
     * @param \Cake\ORM\Table|string $through Name of the Table instance or the instance itself
     * @return this
     */
    function setThrough($through)
    {
        _through = $through;

        return this;
    }

    /**
     * Gets the current join table, either the name of the Table instance or the instance itself.
     *
     * @return \Cake\ORM\Table|string
     */
    function getThrough()
    {
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
    protected function targetConditions()
    {
        if (_targetConditions != null) {
            return _targetConditions;
        }
        $conditions = this.getConditions();
        if (!is_array($conditions)) {
            return $conditions;
        }
        $matching = [];
        $alias = this.getAlias() . ".";
        foreach ($conditions as $field: $value) {
            if (is_string($field) && strpos($field, $alias) == 0) {
                $matching[$field] = $value;
            } elseif (is_int($field) || $value instanceof IExpression) {
                $matching[$field] = $value;
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
    protected function junctionConditions(): array
    {
        if (_junctionConditions != null) {
            return _junctionConditions;
        }
        $matching = [];
        $conditions = this.getConditions();
        if (!is_array($conditions)) {
            return $matching;
        }
        $alias = _junctionAssociationName() . ".";
        foreach ($conditions as $field: $value) {
            $isString = is_string($field);
            if ($isString && strpos($field, $alias) == 0) {
                $matching[$field] = $value;
            }
            // Assume that operators contain junction conditions.
            // Trying to manage complex conditions could result in incorrect queries.
            if ($isString && in_array(strtoupper($field), ["OR", "NOT", "AND", "XOR"], true)) {
                $matching[$field] = $value;
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
     * @param array<string, mixed>|string|null $type the type of query to perform, if an array is passed,
     *   it will be interpreted as the `$options` parameter
     * @param array<string, mixed> $options The options to for the find
     * @see \Cake\ORM\Table::find()
     * @return \Cake\ORM\Query
     */
    function find($type = null, array $options = []): Query
    {
        $type = $type ?: this.getFinder();
        [$type, $opts] = _extractFinder($type);
        $query = this.getTarget()
            .find($type, $options + $opts)
            .where(this.targetConditions())
            .addDefaultTypes(this.getTarget());

        if (this.junctionConditions()) {
            return _appendJunctionJoin($query);
        }

        return $query;
    }

    /**
     * Append a join to the junction table.
     *
     * @param \Cake\ORM\Query $query The query to append.
     * @param array|null $conditions The query conditions to use.
     * @return \Cake\ORM\Query The modified query.
     */
    protected function _appendJunctionJoin(Query $query, ?array $conditions = null): Query
    {
        $junctionTable = this.junction();
        if ($conditions == null) {
            $belongsTo = $junctionTable.getAssociation(this.getTarget().getAlias());
            $conditions = $belongsTo._joinCondition([
                "foreignKey": this.getTargetForeignKey(),
            ]);
            $conditions += this.junctionConditions();
        }

        $name = _junctionAssociationName();
        /** @var array $joins */
        $joins = $query.clause("join");
        $matching = [
            $name: [
                "table": $junctionTable.getTable(),
                "conditions": $conditions,
                "type": Query::JOIN_TYPE_INNER,
            ],
        ];

        $query
            .addDefaultTypes($junctionTable)
            .join($matching + $joins, [], true);

        return $query;
    }

    /**
     * Replaces existing association links between the source entity and the target
     * with the ones passed. This method does a smart cleanup, links that are already
     * persisted and present in `$targetEntities` will not be deleted, new links will
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
     * On success, the passed `$sourceEntity` will contain `$targetEntities` as value
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
     * @param \Cake\Datasource\EntityInterface $sourceEntity an entity persisted in the source table for
     *   this association
     * @param array $targetEntities list of entities from the target table to be linked
     * @param array<string, mixed> $options list of options to be passed to the internal `save`/`delete` calls
     *   when persisting/updating new links, or deleting existing ones
     * @throws \InvalidArgumentException if non persisted entities are passed or if
     *   any of them is lacking a primary key value
     * @return bool success
     */
    function replaceLinks(EntityInterface $sourceEntity, array $targetEntities, array $options = []): bool
    {
        $bindingKey = (array)this.getBindingKey();
        $primaryValue = $sourceEntity.extract($bindingKey);

        if (count(Hash::filter($primaryValue)) != count($bindingKey)) {
            $message = "Could not find primary key value for source entity";
            throw new InvalidArgumentException($message);
        }

        return this.junction().getConnection().transactional(
            function () use ($sourceEntity, $targetEntities, $primaryValue, $options) {
                $junction = this.junction();
                $target = this.getTarget();

                $foreignKey = (array)this.getForeignKey();
                $assocForeignKey = (array)$junction.getAssociation($target.getAlias()).getForeignKey();

                $prefixedForeignKey = array_map([$junction, "aliasField"], $foreignKey);
                $junctionPrimaryKey = (array)$junction.getPrimaryKey();
                $junctionQueryAlias = $junction.getAlias() . "__matches";

                $keys = $matchesConditions = [];
                foreach (array_merge($assocForeignKey, $junctionPrimaryKey) as $key) {
                    $aliased = $junction.aliasField($key);
                    $keys[$key] = $aliased;
                    $matchesConditions[$aliased] = new IdentifierExpression($junctionQueryAlias . "." . $key);
                }

                // Use association to create row selection
                // with finders & association conditions.
                $matches = _appendJunctionJoin(this.find())
                    .select($keys)
                    .where(array_combine($prefixedForeignKey, $primaryValue));

                // Create a subquery join to ensure we get
                // the correct entity passed to callbacks.
                $existing = $junction.query()
                    .from([$junctionQueryAlias: $matches])
                    .innerJoin(
                        [$junction.getAlias(): $junction.getTable()],
                        $matchesConditions
                    );

                $jointEntities = _collectJointEntities($sourceEntity, $targetEntities);
                $inserts = _diffLinks($existing, $jointEntities, $targetEntities, $options);
                if ($inserts == false) {
                    return false;
                }

                if ($inserts && !_saveTarget($sourceEntity, $inserts, $options)) {
                    return false;
                }

                $property = this.getProperty();

                if (count($inserts)) {
                    $inserted = array_combine(
                        array_keys($inserts),
                        (array)$sourceEntity.get($property)
                    ) ?: [];
                    $targetEntities = $inserted + $targetEntities;
                }

                ksort($targetEntities);
                $sourceEntity.set($property, array_values($targetEntities));
                $sourceEntity.setDirty($property, false);

                return true;
            }
        );
    }

    /**
     * Helper method used to delete the difference between the links passed in
     * `$existing` and `$jointEntities`. This method will return the values from
     * `$targetEntities` that were not deleted from calculating the difference.
     *
     * @param \Cake\ORM\Query $existing a query for getting existing links
     * @param array<\Cake\Datasource\EntityInterface> $jointEntities link entities that should be persisted
     * @param array $targetEntities entities in target table that are related to
     * the `$jointEntities`
     * @param array<string, mixed> $options list of options accepted by `Table::delete()`
     * @return array|false Array of entities not deleted or false in case of deletion failure for atomic saves.
     */
    protected function _diffLinks(
        Query $existing,
        array $jointEntities,
        array $targetEntities,
        array $options = []
    ) {
        $junction = this.junction();
        $target = this.getTarget();
        $belongsTo = $junction.getAssociation($target.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $assocForeignKey = (array)$belongsTo.getForeignKey();

        $keys = array_merge($foreignKey, $assocForeignKey);
        $deletes = $unmatchedEntityKeys = $present = [];

        foreach ($jointEntities as $i: $entity) {
            $unmatchedEntityKeys[$i] = $entity.extract($keys);
            $present[$i] = array_values($entity.extract($assocForeignKey));
        }

        foreach ($existing as $existingLink) {
            $existingKeys = $existingLink.extract($keys);
            $found = false;
            foreach ($unmatchedEntityKeys as $i: $unmatchedKeys) {
                $matched = false;
                foreach ($keys as $key) {
                    if (is_object($unmatchedKeys[$key]) && is_object($existingKeys[$key])) {
                        // If both sides are an object then use == so that value objects
                        // are seen as equivalent.
                        $matched = $existingKeys[$key] == $unmatchedKeys[$key];
                    } else {
                        // Use strict equality for all other values.
                        $matched = $existingKeys[$key] == $unmatchedKeys[$key];
                    }
                    // Stop checks on first failure.
                    if (!$matched) {
                        break;
                    }
                }
                if ($matched) {
                    // Remove the unmatched entity so we don"t look at it again.
                    unset($unmatchedEntityKeys[$i]);
                    $found = true;
                    break;
                }
            }

            if (!$found) {
                $deletes[] = $existingLink;
            }
        }

        $primary = (array)$target.getPrimaryKey();
        $jointProperty = _junctionProperty;
        foreach ($targetEntities as $k: $entity) {
            if (!($entity instanceof EntityInterface)) {
                continue;
            }
            $key = array_values($entity.extract($primary));
            foreach ($present as $i: $data) {
                if ($key == $data && !$entity.get($jointProperty)) {
                    unset($targetEntities[$k], $present[$i]);
                    break;
                }
            }
        }

        foreach ($deletes as $entity) {
            if (!$junction.delete($entity, $options) && !empty($options["atomic"])) {
                return false;
            }
        }

        return $targetEntities;
    }

    /**
     * Throws an exception should any of the passed entities is not persisted.
     *
     * @param \Cake\Datasource\EntityInterface $sourceEntity the row belonging to the `source` side
     *   of this association
     * @param array<\Cake\Datasource\EntityInterface> $targetEntities list of entities belonging to the `target` side
     *   of this association
     * @return bool
     * @throws \InvalidArgumentException
     */
    protected function _checkPersistenceStatus(EntityInterface $sourceEntity, array $targetEntities): bool
    {
        if ($sourceEntity.isNew()) {
            $error = "Source entity needs to be persisted before links can be created or removed.";
            throw new InvalidArgumentException($error);
        }

        foreach ($targetEntities as $entity) {
            if ($entity.isNew()) {
                $error = "Cannot link entities that have not been persisted yet.";
                throw new InvalidArgumentException($error);
            }
        }

        return true;
    }

    /**
     * Returns the list of joint entities that exist between the source entity
     * and each of the passed target entities
     *
     * @param \Cake\Datasource\EntityInterface $sourceEntity The row belonging to the source side
     *   of this association.
     * @param array $targetEntities The rows belonging to the target side of this
     *   association.
     * @throws \InvalidArgumentException if any of the entities is lacking a primary
     *   key value
     * @return array<\Cake\Datasource\EntityInterface>
     */
    protected function _collectJointEntities(EntityInterface $sourceEntity, array $targetEntities): array
    {
        $target = this.getTarget();
        $source = this.getSource();
        $junction = this.junction();
        $jointProperty = _junctionProperty;
        $primary = (array)$target.getPrimaryKey();

        $result = [];
        $missing = [];

        foreach ($targetEntities as $entity) {
            if (!($entity instanceof EntityInterface)) {
                continue;
            }
            $joint = $entity.get($jointProperty);

            if (!$joint || !($joint instanceof EntityInterface)) {
                $missing[] = $entity.extract($primary);
                continue;
            }

            $result[] = $joint;
        }

        if (empty($missing)) {
            return $result;
        }

        $belongsTo = $junction.getAssociation($target.getAlias());
        $hasMany = $source.getAssociation($junction.getAlias());
        $foreignKey = (array)this.getForeignKey();
        $foreignKey = array_map(function ($key) {
            return $key . " IS";
        }, $foreignKey);
        $assocForeignKey = (array)$belongsTo.getForeignKey();
        $assocForeignKey = array_map(function ($key) {
            return $key . " IS";
        }, $assocForeignKey);
        $sourceKey = $sourceEntity.extract((array)$source.getPrimaryKey());

        $unions = [];
        foreach ($missing as $key) {
            $unions[] = $hasMany.find()
                .where(array_combine($foreignKey, $sourceKey))
                .where(array_combine($assocForeignKey, $key));
        }

        $query = array_shift($unions);
        foreach ($unions as $q) {
            $query.union($q);
        }

        return array_merge($result, $query.toArray());
    }

    /**
     * Returns the name of the association from the target table to the junction table,
     * this name is used to generate alias in the query and to later on retrieve the
     * results.
     *
     * @return string
     */
    protected function _junctionAssociationName(): string
    {
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
     * @param string|null $name The name of the junction table.
     * @return string
     */
    protected function _junctionTableName(?string $name = null): string
    {
        if ($name == null) {
            if (empty(_junctionTableName)) {
                $tablesNames = array_map("Cake\Utility\Inflector::underscore", [
                    this.getSource().getTable(),
                    this.getTarget().getTable(),
                ]);
                sort($tablesNames);
                _junctionTableName = implode("_", $tablesNames);
            }

            return _junctionTableName;
        }

        return _junctionTableName = $name;
    }

    /**
     * Parse extra options passed in the constructor.
     *
     * @param array<string, mixed> $options original list of options passed in constructor
     * @return void
     */
    protected function _options(array $options): void
    {
        if (!empty($options["targetForeignKey"])) {
            this.setTargetForeignKey($options["targetForeignKey"]);
        }
        if (!empty($options["joinTable"])) {
            _junctionTableName($options["joinTable"]);
        }
        if (!empty($options["through"])) {
            this.setThrough($options["through"]);
        }
        if (!empty($options["saveStrategy"])) {
            this.setSaveStrategy($options["saveStrategy"]);
        }
        if (isset($options["sort"])) {
            this.setSort($options["sort"]);
        }
    }
}
