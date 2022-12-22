module uim.cake.orm;

@safe:
import uim.cake;

/**
 * Contains logic to convert array data into entities.
 *
 * Useful when converting request data into entities.
 *
 * @see \Cake\ORM\Table::newEntity()
 * @see \Cake\ORM\Table::newEntities()
 * @see \Cake\ORM\Table::patchEntity()
 * @see \Cake\ORM\Table::patchEntities()
 */
class Marshaller
{
    use AssociationsNormalizerTrait;

    /**
     * The table instance this marshaller is for.
     *
     * @var \Cake\ORM\Table
     */
    protected _table;

    /**
     * Constructor.
     *
     * @param \Cake\ORM\Table myTable The table this marshaller is for.
     */
    this(Table myTable) {
        _table = myTable;
    }

    /**
     * Build the map of property: marshalling callable.
     *
     * @param array myData The data being marshalled.
     * @param array<string, mixed> myOptions List of options containing the "associated" key.
     * @throws \InvalidArgumentException When associations do not exist.
     * @return array
     */
    protected array _buildPropertyMap(array myData, array myOptions) {
        $map = [];
        $schema = _table.getSchema();

        // Is a concrete column?
        foreach (array_keys(myData) as $prop) {
            $prop = (string)$prop;
            $columnType = $schema.getColumnType($prop);
            if ($columnType) {
                $map[$prop] = function (myValue, $entity) use ($columnType) {
                    return TypeFactory::build($columnType).marshal(myValue);
                };
            }
        }

        // Map associations
        myOptions["associated"] = myOptions["associated"] ?? [];
        $include = _normalizeAssociations(myOptions["associated"]);
        foreach ($include as myKey: $nested) {
            if (is_int(myKey) && is_scalar($nested)) {
                myKey = $nested;
                $nested = [];
            }
            // If the key is not a special field like _ids or _joinData
            // it is a missing association that we should error on.
            if (!_table.hasAssociation(myKey)) {
                if (substr(myKey, 0, 1) != "_") {
                    throw new InvalidArgumentException(sprintf(
                        "Cannot marshal data for "%s" association. It is not associated with "%s".",
                        (string)myKey,
                        _table.getAlias()
                    ));
                }
                continue;
            }
            $assoc = _table.getAssociation(myKey);

            if (isset(myOptions["forceNew"])) {
                $nested["forceNew"] = myOptions["forceNew"];
            }
            if (isset(myOptions["isMerge"])) {
                $callback = function (myValue, $entity) use ($assoc, $nested) {
                    /** @var \Cake\Datasource\IEntity $entity */
                    myOptions = $nested + ["associated": [], "association": $assoc];

                    return _mergeAssociation($entity.get($assoc.getProperty()), $assoc, myValue, myOptions);
                };
            } else {
                $callback = function (myValue, $entity) use ($assoc, $nested) {
                    myOptions = $nested + ["associated": []];

                    return _marshalAssociation($assoc, myValue, myOptions);
                };
            }
            $map[$assoc.getProperty()] = $callback;
        }

        $behaviors = _table.behaviors();
        foreach ($behaviors.loaded() as myName) {
            $behavior = $behaviors.get(myName);
            if ($behavior instanceof IPropertyMarshal) {
                $map += $behavior.buildMarshalMap(this, $map, myOptions);
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
     * myResult = $marshaller.one(myData, [
     *   "associated": ["Tags": ["onlyIds": true]]
     * ]);
     * ```
     *
     * ```
     * myResult = $marshaller.one(myData, [
     *   "associated": [
     *     "Tags": ["accessibleFields": ["*": true]]
     *   ]
     * ]);
     * ```
     *
     * @param array myData The data to hydrate.
     * @param array<string, mixed> myOptions List of options
     * @return \Cake\Datasource\IEntity
     * @see \Cake\ORM\Table::newEntity()
     * @see \Cake\ORM\Entity::$_accessible
     */
    function one(array myData, array myOptions = []): IEntity
    {
        [myData, myOptions] = _prepareDataAndOptions(myData, myOptions);

        $primaryKey = (array)_table.getPrimaryKey();
        $entityClass = _table.getEntityClass();
        $entity = new $entityClass();
        $entity.setSource(_table.getRegistryAlias());

        if (isset(myOptions["accessibleFields"])) {
            foreach ((array)myOptions["accessibleFields"] as myKey: myValue) {
                $entity.setAccess(myKey, myValue);
            }
        }
        myErrors = _validate(myData, myOptions, true);

        myOptions["isMerge"] = false;
        $propertyMap = _buildPropertyMap(myData, myOptions);
        $properties = [];
        foreach (myData as myKey: myValue) {
            if (!empty(myErrors[myKey])) {
                if ($entity instanceof InvalidPropertyInterface) {
                    $entity.setInvalidField(myKey, myValue);
                }
                continue;
            }

            if (myValue == "" && in_array(myKey, $primaryKey, true)) {
                // Skip marshalling "" for pk fields.
                continue;
            }
            if (isset($propertyMap[myKey])) {
                $properties[myKey] = $propertyMap[myKey](myValue, $entity);
            } else {
                $properties[myKey] = myValue;
            }
        }

        if (isset(myOptions["fields"])) {
            foreach ((array)myOptions["fields"] as myField) {
                if (array_key_exists(myField, $properties)) {
                    $entity.set(myField, $properties[myField]);
                }
            }
        } else {
            $entity.set($properties);
        }

        // Don"t flag clean association entities as
        // dirty so we don"t persist empty records.
        foreach ($properties as myField: myValue) {
            if (myValue instanceof IEntity) {
                $entity.setDirty(myField, myValue.isDirty());
            }
        }

        $entity.setErrors(myErrors);
        this.dispatchAfterMarshal($entity, myData, myOptions);

        return $entity;
    }

    /**
     * Returns the validation errors for a data set based on the passed options
     *
     * @param array myData The data to validate.
     * @param array<string, mixed> myOptions The options passed to this marshaller.
     * @param bool $isNew Whether it is a new entity or one to be updated.
     * @return array The list of validation errors.
     * @throws \RuntimeException If no validator can be created.
     */
    protected array _validate(array myData, array myOptions, bool $isNew) {
        if (!myOptions["validate"]) {
            return [];
        }

        $validator = null;
        if (myOptions["validate"] == true) {
            $validator = _table.getValidator();
        } elseif (is_string(myOptions["validate"])) {
            $validator = _table.getValidator(myOptions["validate"]);
        } elseif (is_object(myOptions["validate"])) {
            deprecationWarning(
                "Passing validator instance for the `validate` option is deprecated,"
                . " use `ValidatorAwareTrait::setValidator() instead.`"
            );

            /** @var \Cake\Validation\Validator $validator */
            $validator = myOptions["validate"];
        }

        if ($validator is null) {
            throw new RuntimeException(
                sprintf("validate must be a boolean, a string or an object. Got %s.", getTypeName(myOptions["validate"]))
            );
        }

        return $validator.validate(myData, $isNew);
    }

    /**
     * Returns data and options prepared to validate and marshall.
     *
     * @param array myData The data to prepare.
     * @param array<string, mixed> myOptions The options passed to this marshaller.
     * @return array An array containing prepared data and options.
     */
    protected array _prepareDataAndOptions(array myData, array myOptions) {
        myOptions += ["validate": true];

        myTableName = _table.getAlias();
        if (isset(myData[myTableName])) {
            myData += myData[myTableName];
            unset(myData[myTableName]);
        }

        myData = new ArrayObject(myData);
        myOptions = new ArrayObject(myOptions);
        _table.dispatchEvent("Model.beforeMarshal", compact("data", "options"));

        return [(array)myData, (array)myOptions];
    }

    /**
     * Create a new sub-marshaller and marshal the associated data.
     *
     * @param \Cake\ORM\Association $assoc The association to marshall
     * @param mixed myValue The data to hydrate. If not an array, this method will return null.
     * @param array<string, mixed> myOptions List of options.
     * @return \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity>|null
     */
    protected auto _marshalAssociation(Association $assoc, myValue, array myOptions) {
        if (!is_array(myValue)) {
            return null;
        }
        myTargetTable = $assoc.getTarget();
        $marshaller = myTargetTable.marshaller();
        myTypes = [Association::ONE_TO_ONE, Association::MANY_TO_ONE];
        myType = $assoc.type();
        if (in_array(myType, myTypes, true)) {
            return $marshaller.one(myValue, myOptions);
        }
        if (myType == Association::ONE_TO_MANY || myType == Association::MANY_TO_MANY) {
            $hasIds = array_key_exists("_ids", myValue);
            $onlyIds = array_key_exists("onlyIds", myOptions) && myOptions["onlyIds"];

            if ($hasIds && is_array(myValue["_ids"])) {
                return _loadAssociatedByIds($assoc, myValue["_ids"]);
            }
            if ($hasIds || $onlyIds) {
                return [];
            }
        }
        if (myType == Association::MANY_TO_MANY) {
            /** @psalm-suppress ArgumentTypeCoercion */
            return $marshaller._belongsToMany($assoc, myValue, myOptions);
        }

        return $marshaller.many(myValue, myOptions);
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
     * @param array myData The data to hydrate.
     * @param array<string, mixed> myOptions List of options
     * @return array<\Cake\Datasource\IEntity> An array of hydrated records.
     * @see \Cake\ORM\Table::newEntities()
     * @see \Cake\ORM\Entity::$_accessible
     */
    array many(array myData, array myOptions = []) {
        $output = [];
        foreach (myData as $record) {
            if (!is_array($record)) {
                continue;
            }
            $output[] = this.one($record, myOptions);
        }

        return $output;
    }

    /**
     * Marshals data for belongsToMany associations.
     *
     * Builds the related entities and handles the special casing
     * for junction table entities.
     *
     * @param \Cake\ORM\Association\BelongsToMany $assoc The association to marshal.
     * @param array myData The data to convert into entities.
     * @param array<string, mixed> myOptions List of options.
     * @return array<\Cake\Datasource\IEntity> An array of built entities.
     * @throws \BadMethodCallException
     * @throws \InvalidArgumentException
     * @throws \RuntimeException
     */
    protected array _belongsToMany(BelongsToMany $assoc, array myData, array myOptions = []) {
        $associated = myOptions["associated"] ?? [];
        $forceNew = myOptions["forceNew"] ?? false;

        myData = array_values(myData);

        myTarget = $assoc.getTarget();
        $primaryKey = array_flip((array)myTarget.getPrimaryKey());
        $records = $conditions = [];
        $primaryCount = count($primaryKey);

        foreach (myData as $i: $row) {
            if (!is_array($row)) {
                continue;
            }
            if (array_intersect_key($primaryKey, $row) == $primaryKey) {
                myKeys = array_intersect_key($row, $primaryKey);
                if (count(myKeys) == $primaryCount) {
                    $rowConditions = [];
                    foreach (myKeys as myKey: myValue) {
                        $rowConditions[][myTarget.aliasField(myKey)] = myValue;
                    }

                    if ($forceNew && !myTarget.exists($rowConditions)) {
                        $records[$i] = this.one($row, myOptions);
                    }

                    $conditions = array_merge($conditions, $rowConditions);
                }
            } else {
                $records[$i] = this.one($row, myOptions);
            }
        }

        if (!empty($conditions)) {
            myQuery = myTarget.find();
            myQuery.andWhere(function ($exp) use ($conditions) {
                /** @var \Cake\Database\Expression\QueryExpression $exp */
                return $exp.or($conditions);
            });

            myKeyFields = array_keys($primaryKey);

            $existing = [];
            foreach (myQuery as $row) {
                $k = implode(";", $row.extract(myKeyFields));
                $existing[$k] = $row;
            }

            foreach (myData as $i: $row) {
                myKey = [];
                foreach (myKeyFields as $k) {
                    if (isset($row[$k])) {
                        myKey[] = $row[$k];
                    }
                }
                myKey = implode(";", myKey);

                // Update existing record and child associations
                if (isset($existing[myKey])) {
                    $records[$i] = this.merge($existing[myKey], myData[$i], myOptions);
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
            if (isset(myData[$i]["_joinData"])) {
                $joinData = $jointMarshaller.one(myData[$i]["_joinData"], $nested);
                $record.set("_joinData", $joinData);
            }
        }

        return $records;
    }

    /**
     * Loads a list of belongs to many from ids.
     *
     * @param \Cake\ORM\Association $assoc The association class for the belongsToMany association.
     * @param array $ids The list of ids to load.
     * @return array<\Cake\Datasource\IEntity> An array of entities.
     */
    protected array _loadAssociatedByIds(Association $assoc, array $ids) {
        if (empty($ids)) {
            return [];
        }

        myTarget = $assoc.getTarget();
        $primaryKey = (array)myTarget.getPrimaryKey();
        $multi = count($primaryKey) > 1;
        $primaryKey = array_map([myTarget, "aliasField"], $primaryKey);

        if ($multi) {
            $first = current($ids);
            if (!is_array($first) || count($first) != count($primaryKey)) {
                return [];
            }
            myType = [];
            $schema = myTarget.getSchema();
            foreach ((array)myTarget.getPrimaryKey() as $column) {
                myType[] = $schema.getColumnType($column);
            }
            $filter = new TupleComparison($primaryKey, $ids, myType, "IN");
        } else {
            $filter = [$primaryKey[0] . " IN": $ids];
        }

        return myTarget.find().where($filter).toArray();
    }

    /**
     * Merges `myData` into `$entity` and recursively does the same for each one of
     * the association names passed in `myOptions`. When merging associations, if an
     * entity is not present in the parent entity for a given association, a new one
     * will be created.
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `myData` array will appear, those that can be matched by primary key will get
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
     * myResult = $marshaller.merge($entity, myData, [
     *   "associated": ["Tags": ["onlyIds": true]]
     * ]);
     * ```
     *
     * @param \Cake\Datasource\IEntity $entity the entity that will get the
     * data merged in
     * @param array myData key value list of fields to be merged into the entity
     * @param array<string, mixed> myOptions List of options.
     * @return \Cake\Datasource\IEntity
     * @see \Cake\ORM\Entity::$_accessible
     */
    function merge(IEntity $entity, array myData, array myOptions = []): IEntity
    {
        [myData, myOptions] = _prepareDataAndOptions(myData, myOptions);

        $isNew = $entity.isNew();
        myKeys = [];

        if (!$isNew) {
            myKeys = $entity.extract((array)_table.getPrimaryKey());
        }

        if (isset(myOptions["accessibleFields"])) {
            foreach ((array)myOptions["accessibleFields"] as myKey: myValue) {
                $entity.setAccess(myKey, myValue);
            }
        }

        myErrors = _validate(myData + myKeys, myOptions, $isNew);
        myOptions["isMerge"] = true;
        $propertyMap = _buildPropertyMap(myData, myOptions);
        $properties = [];
        foreach (myData as myKey: myValue) {
            if (!empty(myErrors[myKey])) {
                if ($entity instanceof InvalidPropertyInterface) {
                    $entity.setInvalidField(myKey, myValue);
                }
                continue;
            }
            $original = $entity.get(myKey);

            if (isset($propertyMap[myKey])) {
                myValue = $propertyMap[myKey](myValue, $entity);

                // Don"t dirty scalar values and objects that didn"t
                // change. Arrays will always be marked as dirty because
                // the original/updated list could contain references to the
                // same objects, even though those objects may have changed internally.
                if (
                    (
                        is_scalar(myValue)
                        && $original == myValue
                    )
                    || (
                        myValue is null
                        && $original == myValue
                    )
                    || (
                        is_object(myValue)
                        && !(myValue instanceof IEntity)
                        && $original == myValue
                    )
                ) {
                    continue;
                }
            }
            $properties[myKey] = myValue;
        }

        $entity.setErrors(myErrors);
        if (!isset(myOptions["fields"])) {
            $entity.set($properties);

            foreach ($properties as myField: myValue) {
                if (myValue instanceof IEntity) {
                    $entity.setDirty(myField, myValue.isDirty());
                }
            }
            this.dispatchAfterMarshal($entity, myData, myOptions);

            return $entity;
        }

        foreach ((array)myOptions["fields"] as myField) {
            if (!array_key_exists(myField, $properties)) {
                continue;
            }
            $entity.set(myField, $properties[myField]);
            if ($properties[myField] instanceof IEntity) {
                $entity.setDirty(myField, $properties[myField].isDirty());
            }
        }
        this.dispatchAfterMarshal($entity, myData, myOptions);

        return $entity;
    }

    /**
     * Merges each of the elements from `myData` into each of the entities in `$entities`
     * and recursively does the same for each of the association names passed in
     * `myOptions`. When merging associations, if an entity is not present in the parent
     * entity for a given association, a new one will be created.
     *
     * Records in `myData` are matched against the entities using the primary key
     * column. Entries in `$entities` that cannot be matched to any record in
     * `myData` will be discarded. Records in `myData` that could not be matched will
     * be marshalled as a new entity.
     *
     * When merging HasMany or BelongsToMany associations, all the entities in the
     * `myData` array will appear, those that can be matched by primary key will get
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
     * @param iterable<\Cake\Datasource\IEntity> $entities the entities that will get the
     *   data merged in
     * @param array myData list of arrays to be merged into the entities
     * @param array<string, mixed> myOptions List of options.
     * @return array<\Cake\Datasource\IEntity>
     * @see \Cake\ORM\Entity::$_accessible
     * @psalm-suppress NullArrayOffset
     */
    array mergeMany(iterable $entities, array myData, array myOptions = []) {
        $primary = (array)_table.getPrimaryKey();

        $indexed = (new Collection(myData))
            .groupBy(function ($el) use ($primary) {
                myKeys = [];
                foreach ($primary as myKey) {
                    myKeys[] = $el[myKey] ?? "";
                }

                return implode(";", myKeys);
            })
            .map(function ($element, myKey) {
                return myKey == "" ? $element : $element[0];
            })
            .toArray();

        $new = $indexed[""] ?? [];
        unset($indexed[""]);
        $output = [];

        foreach ($entities as $entity) {
            if (!($entity instanceof IEntity)) {
                continue;
            }

            myKey = implode(";", $entity.extract($primary));
            if (!isset($indexed[myKey])) {
                continue;
            }

            $output[] = this.merge($entity, $indexed[myKey], myOptions);
            unset($indexed[myKey]);
        }

        $conditions = (new Collection($indexed))
            .map(function (myData, myKey) {
                return explode(";", (string)myKey);
            })
            .filter(function (myKeys) use ($primary) {
                return count(Hash::filter(myKeys)) == count($primary);
            })
            .reduce(function ($conditions, myKeys) use ($primary) {
                myFields = array_map([_table, "aliasField"], $primary);
                $conditions["OR"][] = array_combine(myFields, myKeys);

                return $conditions;
            }, ["OR": []]);
        $maybeExistentQuery = _table.find().where($conditions);

        if (!empty($indexed) && count($maybeExistentQuery.clause("where"))) {
            foreach ($maybeExistentQuery as $entity) {
                myKey = implode(";", $entity.extract($primary));
                if (isset($indexed[myKey])) {
                    $output[] = this.merge($entity, $indexed[myKey], myOptions);
                    unset($indexed[myKey]);
                }
            }
        }

        foreach ((new Collection($indexed)).append($new) as myValue) {
            if (!is_array(myValue)) {
                continue;
            }
            $output[] = this.one(myValue, myOptions);
        }

        return $output;
    }

    /**
     * Creates a new sub-marshaller and merges the associated data.
     *
     * @param \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity> $original The original entity
     * @param \Cake\ORM\Association $assoc The association to merge
     * @param mixed myValue The array of data to hydrate. If not an array, this method will return null.
     * @param array<string, mixed> myOptions List of options.
     * @return \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity>|null
     */
    protected auto _mergeAssociation($original, Association $assoc, myValue, array myOptions) {
        if (!$original) {
            return _marshalAssociation($assoc, myValue, myOptions);
        }
        if (!is_array(myValue)) {
            return null;
        }

        myTargetTable = $assoc.getTarget();
        $marshaller = myTargetTable.marshaller();
        myTypes = [Association::ONE_TO_ONE, Association::MANY_TO_ONE];
        myType = $assoc.type();
        if (in_array(myType, myTypes, true)) {
            /** @psalm-suppress PossiblyInvalidArgument, ArgumentTypeCoercion */
            return $marshaller.merge($original, myValue, myOptions);
        }
        if (myType == Association::MANY_TO_MANY) {
            /** @psalm-suppress PossiblyInvalidArgument, ArgumentTypeCoercion */
            return $marshaller._mergeBelongsToMany($original, $assoc, myValue, myOptions);
        }

        if (myType == Association::ONE_TO_MANY) {
            $hasIds = array_key_exists("_ids", myValue);
            $onlyIds = array_key_exists("onlyIds", myOptions) && myOptions["onlyIds"];
            if ($hasIds && is_array(myValue["_ids"])) {
                return _loadAssociatedByIds($assoc, myValue["_ids"]);
            }
            if ($hasIds || $onlyIds) {
                return [];
            }
        }

        /** @psalm-suppress PossiblyInvalidArgument */
        return $marshaller.mergeMany($original, myValue, myOptions);
    }

    /**
     * Creates a new sub-marshaller and merges the associated data for a BelongstoMany
     * association.
     *
     * @param array<\Cake\Datasource\IEntity> $original The original entities list.
     * @param \Cake\ORM\Association\BelongsToMany $assoc The association to marshall
     * @param array myValue The data to hydrate
     * @param array<string, mixed> myOptions List of options.
     * @return array<\Cake\Datasource\IEntity>
     */
    protected array _mergeBelongsToMany(array $original, BelongsToMany $assoc, array myValue, array myOptions) {
        $associated = myOptions["associated"] ?? [];

        $hasIds = array_key_exists("_ids", myValue);
        $onlyIds = array_key_exists("onlyIds", myOptions) && myOptions["onlyIds"];

        if ($hasIds && is_array(myValue["_ids"])) {
            return _loadAssociatedByIds($assoc, myValue["_ids"]);
        }
        if ($hasIds || $onlyIds) {
            return [];
        }

        if (!empty($associated) && !in_array("_joinData", $associated, true) && !isset($associated["_joinData"])) {
            return this.mergeMany($original, myValue, myOptions);
        }

        return _mergeJoinData($original, $assoc, myValue, myOptions);
    }

    /**
     * Merge the special _joinData property into the entity set.
     *
     * @param array<\Cake\Datasource\IEntity> $original The original entities list.
     * @param \Cake\ORM\Association\BelongsToMany $assoc The association to marshall
     * @param array myValue The data to hydrate
     * @param array<string, mixed> myOptions List of options.
     * @return array<\Cake\Datasource\IEntity> An array of entities
     */
    protected array _mergeJoinData(array $original, BelongsToMany $assoc, array myValue, array myOptions) {
        $associated = myOptions["associated"] ?? [];
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

        myOptions["accessibleFields"] = ["_joinData": true];

        $records = this.mergeMany($original, myValue, myOptions);
        foreach ($records as $record) {
            $hash = spl_object_hash($record);
            myValue = $record.get("_joinData");

            // Already an entity, no further marshalling required.
            if (myValue instanceof IEntity) {
                continue;
            }

            // Scalar data can"t be handled
            if (!is_array(myValue)) {
                $record.unset("_joinData");
                continue;
            }

            // Marshal data into the old object, or make a new joinData object.
            if (isset($extra[$hash])) {
                $record.set("_joinData", $marshaller.merge($extra[$hash], myValue, $nested));
            } else {
                $joinData = $marshaller.one(myValue, $nested);
                $record.set("_joinData", $joinData);
            }
        }

        return $records;
    }

    /**
     * dispatch Model.afterMarshal event.
     *
     * @param \Cake\Datasource\IEntity $entity The entity that was marshaled.
     * @param array myData readOnly myData to use.
     * @param array<string, mixed> myOptions List of options that are readOnly.
     */
    protected void dispatchAfterMarshal(IEntity $entity, array myData, array myOptions = []) {
        myData = new ArrayObject(myData);
        myOptions = new ArrayObject(myOptions);
        _table.dispatchEvent("Model.afterMarshal", compact("entity", "data", "options"));
    }
}
