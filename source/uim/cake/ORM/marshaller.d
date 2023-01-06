module uim.cake.ORM;

use ArrayObject;
import uim.cake.collections.Collection;
import uim.cake.databases.expressions.TupleComparison;
import uim.cake.databases.TypeFactory;
import uim.cake.datasources.IEntity;
import uim.cake.datasources.InvalidPropertyInterface;
import uim.cake.orm.associations.BelongsToMany;
import uim.cake.utilities.Hash;
use InvalidArgumentException;
use RuntimeException;

/**
 * Contains logic to convert array data into entities.
 *
 * Useful when converting request data into entities.
 *
 * @see uim.cake.orm.Table::newEntity()
 * @see uim.cake.orm.Table::newEntities()
 * @see uim.cake.orm.Table::patchEntity()
 * @see uim.cake.orm.Table::patchEntities()
 */
class Marshaller
{
    use AssociationsNormalizerTrait;

    /**
     * The table instance this marshaller is for.
     *
     * @var uim.cake.orm.Table
     */
    protected _table;

    /**
     * Constructor.
     *
     * @param uim.cake.orm.Table $table The table this marshaller is for.
     */
    this(Table $table) {
        _table = $table;
    }

    /**
     * Build the map of property: marshalling callable.
     *
     * @param array $data The data being marshalled.
     * @param array<string, mixed> $options List of options containing the "associated" key.
     * @throws \InvalidArgumentException When associations do not exist.
     */
    protected array _buildPropertyMap(array $data, array $options) {
        $map = [];
        $schema = _table.getSchema();

        // Is a concrete column?
        foreach (array_keys($data) as $prop) {
            $prop = (string)$prop;
            $columnType = $schema.getColumnType($prop);
            if ($columnType) {
                $map[$prop] = function ($value, $entity) use ($columnType) {
                    return TypeFactory::build($columnType).marshal($value);
                };
            }
        }

        // Map associations
        $options["associated"] = $options["associated"] ?? [];
        $include = _normalizeAssociations($options["associated"]);
        foreach ($include as $key: $nested) {
            if (is_int($key) && is_scalar($nested)) {
                $key = $nested;
                $nested = [];
            }
            // If the key is not a special field like _ids or _joinData
            // it is a missing association that we should error on.
            if (!_table.hasAssociation($key)) {
                if (substr($key, 0, 1) != "_") {
                    throw new InvalidArgumentException(sprintf(
                        "Cannot marshal data for "%s" association. It is not associated with "%s".",
                        (string)$key,
                        _table.getAlias()
                    ));
                }
                continue;
            }
            $assoc = _table.getAssociation($key);

            if (isset($options["forceNew"])) {
                $nested["forceNew"] = $options["forceNew"];
            }
            if (isset($options["isMerge"])) {
                $callback = function ($value, $entity) use ($assoc, $nested) {
                    /** @var uim.cake.datasources.IEntity $entity */
                    $options = $nested + ["associated": [], "association": $assoc];

                    return _mergeAssociation($entity.get($assoc.getProperty()), $assoc, $value, $options);
                };
            } else {
                $callback = function ($value, $entity) use ($assoc, $nested) {
                    $options = $nested + ["associated": []];

                    return _marshalAssociation($assoc, $value, $options);
                };
            }
            $map[$assoc.getProperty()] = $callback;
        }

        $behaviors = _table.behaviors();
        foreach ($behaviors.loaded() as $name) {
            $behavior = $behaviors.get($name);
            if ($behavior instanceof PropertyMarshalInterface) {
                $map += $behavior.buildMarshalMap(this, $map, $options);
            }
        }

        return $map;
    }

    /**
     * Hydrate one entity and its associated data.
     *
     * ### Options:
     *
     * - validate: Set to false to disable validation. Can also be a string of the validator ruleset to be applied.
     *   Defaults to true/default.
     * - associated: Associations listed here will be marshalled as well. Defaults to null.
     * - fields: An allowed list of fields to be assigned to the entity. If not present,
     *   the accessible fields list in the entity will be used. Defaults to null.
     * - accessibleFields: A list of fields to allow or deny in entity accessible fields. Defaults to null
     * - forceNew: When enabled, belongsToMany associations will have "new" entities created
     *   when primary key values are set, and a record does not already exist. Normally primary key
     *   on missing entities would be ignored. Defaults to false.
     *
     * The above options can be used in each nested `associated` array. In addition to the above
     * options you can also use the `onlyIds` option for HasMany and BelongsToMany associations.
     * When true this option restricts the request data to only be read from `_ids`.
     *
     * ```
     * $result = $marshaller.one($data, [
     *   "associated": ["Tags": ["onlyIds": true]]
     * ]);
     * ```
     *
     * ```
     * $result = $marshaller.one($data, [
     *   "associated": [
     *     "Tags": ["accessibleFields": ["*": true]]
     *   ]
     * ]);
     * ```
     *
     * @param array $data The data to hydrate.
     * @param array<string, mixed> $options List of options
     * @return uim.cake.Datasource\IEntity
     * @see uim.cake.orm.Table::newEntity()
     * @see uim.cake.orm.Entity::_accessible
     */
    function one(array $data, array $options = []): IEntity
    {
        [$data, $options] = _prepareDataAndOptions($data, $options);

        $primaryKey = (array)_table.getPrimaryKey();
        $entityClass = _table.getEntityClass();
        $entity = new $entityClass();
        $entity.setSource(_table.getRegistryAlias());

        if (isset($options["accessibleFields"])) {
            foreach ((array)$options["accessibleFields"] as $key: $value) {
                $entity.setAccess($key, $value);
            }
        }
        $errors = _validate($data, $options, true);

        $options["isMerge"] = false;
        $propertyMap = _buildPropertyMap($data, $options);
        $properties = [];
        foreach ($data as $key: $value) {
            if (!empty($errors[$key])) {
                if ($entity instanceof InvalidPropertyInterface) {
                    $entity.setInvalidField($key, $value);
                }
                continue;
            }

            if ($value == "" && in_array($key, $primaryKey, true)) {
                // Skip marshalling "" for pk fields.
                continue;
            }
            if (isset($propertyMap[$key])) {
                $properties[$key] = $propertyMap[$key]($value, $entity);
            } else {
                $properties[$key] = $value;
            }
        }

        if (isset($options["fields"])) {
            foreach ((array)$options["fields"] as $field) {
                if (array_key_exists($field, $properties)) {
                    $entity.set($field, $properties[$field]);
                }
            }
        } else {
            $entity.set($properties);
        }

        // Don"t flag clean association entities as
        // dirty so we don"t persist empty records.
        foreach ($properties as $field: $value) {
            if ($value instanceof IEntity) {
                $entity.setDirty($field, $value.isDirty());
            }
        }

        $entity.setErrors($errors);
        this.dispatchAfterMarshal($entity, $data, $options);

        return $entity;
    }

    /**
     * Returns the validation errors for a data set based on the passed options
     *
     * @param array $data The data to validate.
     * @param array<string, mixed> $options The options passed to this marshaller.
     * @param bool $isNew Whether it is a new entity or one to be updated.
     * @return array The list of validation errors.
     * @throws \RuntimeException If no validator can be created.
     */
    protected function _validate(array $data, array $options, bool $isNew) {
        if (!$options["validate"]) {
            return [];
        }

        $validator = null;
        if ($options["validate"] == true) {
            $validator = _table.getValidator();
        } elseif (is_string($options["validate"])) {
            $validator = _table.getValidator($options["validate"]);
        } elseif (is_object($options["validate"])) {
            deprecationWarning(
                "Passing validator instance for the `validate` option is deprecated,"
                ~ " use `ValidatorAwareTrait::setValidator() instead.`"
            );

            /** @var uim.cake.validations.Validator $validator */
            $validator = $options["validate"];
        }

        if ($validator == null) {
            throw new RuntimeException(
                sprintf("validate must be a boolean, a string or an object. Got %s.", getTypeName($options["validate"]))
            );
        }

        return $validator.validate($data, $isNew);
    }

    /**
     * Returns data and options prepared to validate and marshall.
     *
     * @param array $data The data to prepare.
     * @param array<string, mixed> $options The options passed to this marshaller.
     * @return array An array containing prepared data and options.
     */
    protected function _prepareDataAndOptions(array $data, array $options) {
        $options += ["validate": true];

        $tableName = _table.getAlias();
        if (isset($data[$tableName]) && is_array($data[$tableName])) {
            $data += $data[$tableName];
            unset($data[$tableName]);
        }

        $data = new ArrayObject($data);
        $options = new ArrayObject($options);
        _table.dispatchEvent("Model.beforeMarshal", compact("data", "options"));

        return [(array)$data, (array)$options];
    }

    /**
     * Create a new sub-marshaller and marshal the associated data.
     *
     * @param uim.cake.orm.Association $assoc The association to marshall
     * @param mixed $value The data to hydrate. If not an array, this method will return null.
     * @param array<string, mixed> $options List of options.
     * @return uim.cake.Datasource\IEntity|array<uim.cake.Datasource\IEntity>|null
     */
    protected function _marshalAssociation(Association $assoc, $value, array $options) {
        if (!is_array($value)) {
            return null;
        }
        $targetTable = $assoc.getTarget();
        $marshaller = $targetTable.marshaller();
        $types = [Association::ONE_TO_ONE, Association::MANY_TO_ONE];
        $type = $assoc.type();
        if (in_array($type, $types, true)) {
            return $marshaller.one($value, $options);
        }
        if ($type == Association::ONE_TO_MANY || $type == Association::MANY_TO_MANY) {
            $hasIds = array_key_exists("_ids", $value);
            $onlyIds = array_key_exists("onlyIds", $options) && $options["onlyIds"];

            if ($hasIds && is_array($value["_ids"])) {
                return _loadAssociatedByIds($assoc, $value["_ids"]);
            }
            if ($hasIds || $onlyIds) {
                return [];
            }
        }
        if ($type == Association::MANY_TO_MANY) {
            /** @psalm-suppress ArgumentTypeCoercion */
            return $marshaller._belongsToMany($assoc, $value, $options);
        }

        return $marshaller.many($value, $options);
    }

    /**
     * Hydrate many entities and their associated data.
     *
     * ### Options:
     *
     * - validate: Set to false to disable validation. Can also be a string of the validator ruleset to be applied.
     *   Defaults to true/default.
     * - associated: Associations listed here will be marshalled as well. Defaults to null.
     * - fields: An allowed list of fields to be assigned to the entity. If not present,
     *   the accessible fields list in the entity will be used. Defaults to null.
     * - accessibleFields: A list of fields to allow or deny in entity accessible fields. Defaults to null
     * - forceNew: When enabled, belongsToMany associations will have "new" entities created
     *   when primary key values are set, and a record does not already exist. Normally primary key
     *   on missing entities would be ignored. Defaults to false.
     *
     * @param array $data The data to hydrate.
     * @param array<string, mixed> $options List of options
     * @return array<uim.cake.Datasource\IEntity> An array of hydrated records.
     * @see uim.cake.orm.Table::newEntities()
     * @see uim.cake.orm.Entity::_accessible
     */
    function many(array $data, array $options = []) {
        $output = [];
        foreach ($data as $record) {
            if (!is_array($record)) {
                continue;
            }
            $output[] = this.one($record, $options);
        }

        return $output;
    }

    /**
     * Marshals data for belongsToMany associations.
     *
     * Builds the related entities and handles the special casing
     * for junction table entities.
     *
     * @param uim.cake.orm.associations.BelongsToMany $assoc The association to marshal.
     * @param array $data The data to convert into entities.
     * @param array<string, mixed> $options List of options.
     * @return array<uim.cake.Datasource\IEntity> An array of built entities.
     * @throws \BadMethodCallException
     * @throws \InvalidArgumentException
     * @throws \RuntimeException
     */
    protected function _belongsToMany(BelongsToMany $assoc, array $data, array $options = []) {
        $associated = $options["associated"] ?? [];
        $forceNew = $options["forceNew"] ?? false;

        $data = array_values($data);

        $target = $assoc.getTarget();
        $primaryKey = array_flip((array)$target.getPrimaryKey());
        $records = $conditions = [];
        $primaryCount = count($primaryKey);

        foreach ($data as $i: $row) {
            if (!is_array($row)) {
                continue;
            }
            if (array_intersect_key($primaryKey, $row) == $primaryKey) {
                $keys = array_intersect_key($row, $primaryKey);
                if (count($keys) == $primaryCount) {
                    $rowConditions = [];
                    foreach ($keys as $key: $value) {
                        $rowConditions[][$target.aliasField($key)] = $value;
                    }

                    if ($forceNew && !$target.exists($rowConditions)) {
                        $records[$i] = this.one($row, $options);
                    }

                    $conditions = array_merge($conditions, $rowConditions);
                }
            } else {
                $records[$i] = this.one($row, $options);
            }
        }

        if (!empty($conditions)) {
            $query = $target.find();
            $query.andWhere(function ($exp) use ($conditions) {
                /** @var uim.cake.databases.Expression\QueryExpression $exp */
                return $exp.or($conditions);
            });

            $keyFields = array_keys($primaryKey);

            $existing = [];
            foreach ($query as $row) {
                $k = implode(";", $row.extract($keyFields));
                $existing[$k] = $row;
            }

            foreach ($data as $i: $row) {
                $key = [];
                foreach ($keyFields as $k) {
                    if (isset($row[$k])) {
                        $key[] = $row[$k];
                    }
                }
                $key = implode(";", $key);

                // Update existing record and child associations
                if (isset($existing[$key])) {
                    $records[$i] = this.merge($existing[$key], $data[$i], $options);
                }
            }
        }

        $jointMarshaller = $assoc.junction().marshaller();

        $nested = [];
        if (isset($associated["_joinData"])) {
            $nested = (array)$associated["_joinData"];
        }

        foreach ($records as $i: $record) {
            // Update junction table data in _joinData.
            if (isset($data[$i]["_joinData"])) {
                $joinData = $jointMarshaller.one($data[$i]["_joinData"], $nested);
                $record.set("_joinData", $joinData);
            }
        }

        return $records;
    }

    /**
     * Loads a list of belongs to many from ids.
     *
     * @param uim.cake.orm.Association $assoc The association class for the belongsToMany association.
     * @param array $ids The list of ids to load.
     * @return array<uim.cake.Datasource\IEntity> An array of entities.
     */
    protected function _loadAssociatedByIds(Association $assoc, array $ids) {
        if (empty($ids)) {
            return [];
        }

        $target = $assoc.getTarget();
        $primaryKey = (array)$target.getPrimaryKey();
        $multi = count($primaryKey) > 1;
        $primaryKey = array_map([$target, "aliasField"], $primaryKey);

        if ($multi) {
            $first = current($ids);
            if (!is_array($first) || count($first) != count($primaryKey)) {
                return [];
            }
            $type = [];
            $schema = $target.getSchema();
            foreach ((array)$target.getPrimaryKey() as $column) {
                $type[] = $schema.getColumnType($column);
            }
            $filter = new TupleComparison($primaryKey, $ids, $type, "IN");
        } else {
            $filter = [$primaryKey[0] ~ " IN": $ids];
        }

        return $target.find().where($filter).toArray();
    }

    /**
     * Merges `$data` into `$entity` and recursively does the same for each one of
     * the association names passed in `$options`. When merging associations, if an
     * entity is not present in the parent entity for a given association, a new one
     * will be created.
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `$data` array will appear, those that can be matched by primary key will get
     * the data merged, but those that cannot, will be discarded. `ids` option can be used
     * to determine whether the association must use the `_ids` format.
     *
     * ### Options:
     *
     * - associated: Associations listed here will be marshalled as well.
     * - validate: Whether to validate data before hydrating the entities. Can
     *   also be set to a string to use a specific validator. Defaults to true/default.
     * - fields: An allowed list of fields to be assigned to the entity. If not present
     *   the accessible fields list in the entity will be used.
     * - accessibleFields: A list of fields to allow or deny in entity accessible fields.
     *
     * The above options can be used in each nested `associated` array. In addition to the above
     * options you can also use the `onlyIds` option for HasMany and BelongsToMany associations.
     * When true this option restricts the request data to only be read from `_ids`.
     *
     * ```
     * $result = $marshaller.merge($entity, $data, [
     *   "associated": ["Tags": ["onlyIds": true]]
     * ]);
     * ```
     *
     * @param uim.cake.Datasource\IEntity $entity the entity that will get the
     * data merged in
     * @param array $data key value list of fields to be merged into the entity
     * @param array<string, mixed> $options List of options.
     * @return uim.cake.Datasource\IEntity
     * @see uim.cake.orm.Entity::_accessible
     */
    function merge(IEntity $entity, array $data, array $options = []): IEntity
    {
        [$data, $options] = _prepareDataAndOptions($data, $options);

        $isNew = $entity.isNew();
        $keys = [];

        if (!$isNew) {
            $keys = $entity.extract((array)_table.getPrimaryKey());
        }

        if (isset($options["accessibleFields"])) {
            foreach ((array)$options["accessibleFields"] as $key: $value) {
                $entity.setAccess($key, $value);
            }
        }

        $errors = _validate($data + $keys, $options, $isNew);
        $options["isMerge"] = true;
        $propertyMap = _buildPropertyMap($data, $options);
        $properties = [];
        foreach ($data as $key: $value) {
            if (!empty($errors[$key])) {
                if ($entity instanceof InvalidPropertyInterface) {
                    $entity.setInvalidField($key, $value);
                }
                continue;
            }
            $original = $entity.get(string aKey);

            if (isset($propertyMap[$key])) {
                $value = $propertyMap[$key]($value, $entity);

                // Don"t dirty scalar values and objects that didn"t
                // change. Arrays will always be marked as dirty because
                // the original/updated list could contain references to the
                // same objects, even though those objects may have changed internally.
                if (
                    (
                        is_scalar($value)
                        && $original == $value
                    )
                    || (
                        $value == null
                        && $original == $value
                    )
                    || (
                        is_object($value)
                        && !($value instanceof IEntity)
                        && $original == $value
                    )
                ) {
                    continue;
                }
            }
            $properties[$key] = $value;
        }

        $entity.setErrors($errors);
        if (!isset($options["fields"])) {
            $entity.set($properties);

            foreach ($properties as $field: $value) {
                if ($value instanceof IEntity) {
                    $entity.setDirty($field, $value.isDirty());
                }
            }
            this.dispatchAfterMarshal($entity, $data, $options);

            return $entity;
        }

        foreach ((array)$options["fields"] as $field) {
            if (!array_key_exists($field, $properties)) {
                continue;
            }
            $entity.set($field, $properties[$field]);
            if ($properties[$field] instanceof IEntity) {
                $entity.setDirty($field, $properties[$field].isDirty());
            }
        }
        this.dispatchAfterMarshal($entity, $data, $options);

        return $entity;
    }

    /**
     * Merges each of the elements from `$data` into each of the entities in `$entities`
     * and recursively does the same for each of the association names passed in
     * `$options`. When merging associations, if an entity is not present in the parent
     * entity for a given association, a new one will be created.
     *
     * Records in `$data` are matched against the entities using the primary key
     * column. Entries in `$entities` that cannot be matched to any record in
     * `$data` will be discarded. Records in `$data` that could not be matched will
     * be marshalled as a new entity.
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `$data` array will appear, those that can be matched by primary key will get
     * the data merged, but those that cannot, will be discarded.
     *
     * ### Options:
     *
     * - validate: Whether to validate data before hydrating the entities. Can
     *   also be set to a string to use a specific validator. Defaults to true/default.
     * - associated: Associations listed here will be marshalled as well.
     * - fields: An allowed list of fields to be assigned to the entity. If not present,
     *   the accessible fields list in the entity will be used.
     * - accessibleFields: A list of fields to allow or deny in entity accessible fields.
     *
     * @param iterable<uim.cake.Datasource\IEntity> $entities the entities that will get the
     *   data merged in
     * @param array $data list of arrays to be merged into the entities
     * @param array<string, mixed> $options List of options.
     * @return array<uim.cake.Datasource\IEntity>
     * @see uim.cake.orm.Entity::_accessible
     * @psalm-suppress NullArrayOffset
     */
    function mergeMany(iterable $entities, array $data, array $options = []) {
        $primary = (array)_table.getPrimaryKey();

        $indexed = (new Collection($data))
            .groupBy(function ($el) use ($primary) {
                $keys = [];
                foreach ($primary as $key) {
                    $keys[] = $el[$key] ?? "";
                }

                return implode(";", $keys);
            })
            .map(function ($element, $key) {
                return $key == "" ? $element : $element[0];
            })
            .toArray();

        $new = $indexed[""] ?? [];
        unset($indexed[""]);
        $output = [];

        foreach ($entities as $entity) {
            if (!($entity instanceof IEntity)) {
                continue;
            }

            $key = implode(";", $entity.extract($primary));
            if (!isset($indexed[$key])) {
                continue;
            }

            $output[] = this.merge($entity, $indexed[$key], $options);
            unset($indexed[$key]);
        }

        $conditions = (new Collection($indexed))
            .map(function ($data, $key) {
                return explode(";", (string)$key);
            })
            .filter(function ($keys) use ($primary) {
                return count(Hash::filter($keys)) == count($primary);
            })
            .reduce(function ($conditions, $keys) use ($primary) {
                $fields = array_map([_table, "aliasField"], $primary);
                $conditions["OR"][] = array_combine($fields, $keys);

                return $conditions;
            }, ["OR": []]);
        $maybeExistentQuery = _table.find().where($conditions);

        if (!empty($indexed) && count($maybeExistentQuery.clause("where"))) {
            foreach ($maybeExistentQuery as $entity) {
                $key = implode(";", $entity.extract($primary));
                if (isset($indexed[$key])) {
                    $output[] = this.merge($entity, $indexed[$key], $options);
                    unset($indexed[$key]);
                }
            }
        }

        foreach ((new Collection($indexed)).append($new) as $value) {
            if (!is_array($value)) {
                continue;
            }
            $output[] = this.one($value, $options);
        }

        return $output;
    }

    /**
     * Creates a new sub-marshaller and merges the associated data.
     *
     * @param uim.cake.Datasource\IEntity|array<uim.cake.Datasource\IEntity> $original The original entity
     * @param uim.cake.orm.Association $assoc The association to merge
     * @param mixed $value The array of data to hydrate. If not an array, this method will return null.
     * @param array<string, mixed> $options List of options.
     * @return uim.cake.Datasource\IEntity|array<uim.cake.Datasource\IEntity>|null
     */
    protected function _mergeAssociation($original, Association $assoc, $value, array $options) {
        if (!$original) {
            return _marshalAssociation($assoc, $value, $options);
        }
        if (!is_array($value)) {
            return null;
        }

        $targetTable = $assoc.getTarget();
        $marshaller = $targetTable.marshaller();
        $types = [Association::ONE_TO_ONE, Association::MANY_TO_ONE];
        $type = $assoc.type();
        if (in_array($type, $types, true)) {
            /** @psalm-suppress PossiblyInvalidArgument, ArgumentTypeCoercion */
            return $marshaller.merge($original, $value, $options);
        }
        if ($type == Association::MANY_TO_MANY) {
            /** @psalm-suppress PossiblyInvalidArgument, ArgumentTypeCoercion */
            return $marshaller._mergeBelongsToMany($original, $assoc, $value, $options);
        }

        if ($type == Association::ONE_TO_MANY) {
            $hasIds = array_key_exists("_ids", $value);
            $onlyIds = array_key_exists("onlyIds", $options) && $options["onlyIds"];
            if ($hasIds && is_array($value["_ids"])) {
                return _loadAssociatedByIds($assoc, $value["_ids"]);
            }
            if ($hasIds || $onlyIds) {
                return [];
            }
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return $marshaller.mergeMany($original, $value, $options);
    }

    /**
     * Creates a new sub-marshaller and merges the associated data for a BelongstoMany
     * association.
     *
     * @param array<uim.cake.Datasource\IEntity> $original The original entities list.
     * @param uim.cake.orm.associations.BelongsToMany $assoc The association to marshall
     * @param array $value The data to hydrate
     * @param array<string, mixed> $options List of options.
     * @return array<uim.cake.Datasource\IEntity>
     */
    protected function _mergeBelongsToMany(array $original, BelongsToMany $assoc, array $value, array $options) {
        $associated = $options["associated"] ?? [];

        $hasIds = array_key_exists("_ids", $value);
        $onlyIds = array_key_exists("onlyIds", $options) && $options["onlyIds"];

        if ($hasIds && is_array($value["_ids"])) {
            return _loadAssociatedByIds($assoc, $value["_ids"]);
        }
        if ($hasIds || $onlyIds) {
            return [];
        }

        if (!empty($associated) && !in_array("_joinData", $associated, true) && !isset($associated["_joinData"])) {
            return this.mergeMany($original, $value, $options);
        }

        return _mergeJoinData($original, $assoc, $value, $options);
    }

    /**
     * Merge the special _joinData property into the entity set.
     *
     * @param array<uim.cake.Datasource\IEntity> $original The original entities list.
     * @param uim.cake.orm.associations.BelongsToMany $assoc The association to marshall
     * @param array $value The data to hydrate
     * @param array<string, mixed> $options List of options.
     * @return array<uim.cake.Datasource\IEntity> An array of entities
     */
    protected function _mergeJoinData(array $original, BelongsToMany $assoc, array $value, array $options) {
        $associated = $options["associated"] ?? [];
        $extra = [];
        foreach ($original as $entity) {
            // Mark joinData as accessible so we can marshal it properly.
            $entity.setAccess("_joinData", true);

            $joinData = $entity.get("_joinData");
            if ($joinData && $joinData instanceof IEntity) {
                $extra[spl_object_hash($entity)] = $joinData;
            }
        }

        $joint = $assoc.junction();
        $marshaller = $joint.marshaller();

        $nested = [];
        if (isset($associated["_joinData"])) {
            $nested = (array)$associated["_joinData"];
        }

        $options["accessibleFields"] = ["_joinData": true];

        $records = this.mergeMany($original, $value, $options);
        foreach ($records as $record) {
            $hash = spl_object_hash($record);
            $value = $record.get("_joinData");

            // Already an entity, no further marshalling required.
            if ($value instanceof IEntity) {
                continue;
            }

            // Scalar data can"t be handled
            if (!is_array($value)) {
                $record.unset("_joinData");
                continue;
            }

            // Marshal data into the old object, or make a new joinData object.
            if (isset($extra[$hash])) {
                $record.set("_joinData", $marshaller.merge($extra[$hash], $value, $nested));
            } else {
                $joinData = $marshaller.one($value, $nested);
                $record.set("_joinData", $joinData);
            }
        }

        return $records;
    }

    /**
     * dispatch Model.afterMarshal event.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity that was marshaled.
     * @param array $data readOnly $data to use.
     * @param array<string, mixed> $options List of options that are readOnly.
     */
    protected void dispatchAfterMarshal(IEntity $entity, array $data, array $options = []) {
        $data = new ArrayObject($data);
        $options = new ArrayObject($options);
        _table.dispatchEvent("Model.afterMarshal", compact("entity", "data", "options"));
    }
}
