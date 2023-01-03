module uim.cake.orm;

@safe:
import uim.cake;

/**
 * An Association is a relationship established between two tables and is used
 * to configure and customize the way interconnected records are retrieved.
 *
 * @mixin uim.cake.orm.Table
 */
abstract class Association {
    use ConventionsTrait;
    use LocatorAwareTrait;


    // ----------

    /**
     * The field name in the owning side table that is used to match with the foreignKey
     *
     * @var array<string>|string|null
     */
    protected _bindingKey;

    /**
     * The name of the field representing the foreign key to the table to load
     *
     * @var array<string>|string
     */
    protected _foreignKey;

    /**
     * A list of conditions to be always included when fetching records from
     * the target association
     *
     * @var \Closure|array
     */
    protected _conditions = [];

    /**
     * Whether the records on the target table are dependent on the source table,
     * often used to indicate that records should be removed if the owning record in
     * the source table is deleted.
     *
     * @var bool
     */
    protected _dependent = false;

    /**
     * Whether cascaded deletes should also fire callbacks.
     *
     * @var bool
     */
    protected _cascadeCallbacks = false;

    /**
     * Source table instance
     *
     * @var uim.cake.orm.Table
     */
    protected _sourceTable;

    /**
     * Target table instance
     *
     * @var uim.cake.orm.Table
     */
    protected _targetTable;

    /**
     * The type of join to be used when adding the association to a query
     */
    protected string _joinType = Query::JOIN_TYPE_LEFT;

    /**
     * The property name that should be filled with data from the target table
     * in the source table record.
     */
    protected string _propertyName;

    /**
     * The strategy name to be used to fetch associated records. Some association
     * types might not implement but one strategy to fetch records.
     */
    protected string _strategy = self::STRATEGY_JOIN;

    /**
     * The default finder name to use for fetching rows from the target table
     * With array value, finder name and default options are allowed.
     *
     * @var array|string
     */
    protected _finder = "all";

    /**
     * Valid strategies for this association. Subclasses can narrow this down.
     *
     * @var array<string>
     */
    protected _validStrategies = [
        self::STRATEGY_JOIN,
        self::STRATEGY_SELECT,
        self::STRATEGY_SUBQUERY,
    ];

    /**
     * Constructor. Subclasses can override _options function to get the original
     * list of passed options if expecting any other special key
     *
     * @param string myAlias The name given to the association
     * @param array<string, mixed> myOptions A list of properties to be set on this object
     */
    this(string myAlias, array myOptions = []) {
        $defaults = [
            "cascadeCallbacks",
            "className",
            "conditions",
            "dependent",
            "finder",
            "bindingKey",
            "foreignKey",
            "joinType",
            "tableLocator",
            "propertyName",
            "sourceTable",
            "targetTable",
        ];
        foreach ($defaults as $property) {
            if (isset(myOptions[$property])) {
                this.{"_" ~ $property} = myOptions[$property];
            }
        }

        if (empty(_className)) {
            _className = myAlias;
        }

        [, myName] = pluginSplit(myAlias);
        _name = myName;

        _options(myOptions);

        if (!empty(myOptions["strategy"])) {
            this.setStrategy(myOptions["strategy"]);
        }
    }

    // ------------

    /**
     * Sets whether cascaded deletes should also fire callbacks.
     *
     * @param bool $cascadeCallbacks cascade callbacks switch value
     * @return this
     */
    auto setCascadeCallbacks(bool $cascadeCallbacks) {
        _cascadeCallbacks = $cascadeCallbacks;

        return this;
    }

    /**
     * Gets whether cascaded deletes should also fire callbacks.
     */
    bool getCascadeCallbacks() {
        return _cascadeCallbacks;
    }

    /**
     * Sets the class name of the target table object.
     *
     * @param string myClassName Class name to set.
     * @return this
     * @throws \InvalidArgumentException In case the class name is set after the target table has been
     *  resolved, and it doesn"t match the target table"s class name.
     */
    auto setClassName(string myClassName) {
        if (
            _targetTable  !is null &&
            get_class(_targetTable) != App::className(myClassName, "Model/Table", "Table")
        ) {
            throw new InvalidArgumentException(sprintf(
                "The class name "%s" doesn\"t match the target table class name of "%s".",
                myClassName,
                get_class(_targetTable)
            ));
        }

        _className = myClassName;

        return this;
    }

    /**
     * Gets the class name of the target table object.
     */
    string getClassName() {
        return _className;
    }

    /**
     * Sets the table instance for the source side of the association.
     *
     * @param uim.cake.orm.Table myTable the instance to be assigned as source side
     * @return this
     */
    auto setSource(Table myTable) {
        _sourceTable = myTable;

        return this;
    }

    /**
     * Gets the table instance for the source side of the association.
     *
     * @return uim.cake.orm.Table
     */
    auto getSource(): Table
    {
        return _sourceTable;
    }

    /**
     * Sets the table instance for the target side of the association.
     *
     * @param uim.cake.orm.Table myTable the instance to be assigned as target side
     * @return this
     */
    auto setTarget(Table myTable) {
        _targetTable = myTable;

        return this;
    }

    /**
     * Gets the table instance for the target side of the association.
     *
     * @return uim.cake.orm.Table
     */
    auto getTarget(): Table
    {
        if (_targetTable is null) {
            if (indexOf(_className, ".")) {
                [myPlugin] = pluginSplit(_className, true);
                $registryAlias = (string)myPlugin . _name;
            } else {
                $registryAlias = _name;
            }

            myTableLocator = this.getTableLocator();

            myConfig = [];
            $exists = myTableLocator.exists($registryAlias);
            if (!$exists) {
                myConfig = ["className":_className];
            }
            _targetTable = myTableLocator.get($registryAlias, myConfig);

            if ($exists) {
                myClassName = App::className(_className, "Model/Table", "Table") ?: Table::class;

                if (!_targetTable instanceof myClassName) {
                    myErrorMessage = "%s association "%s" of type "%s" to "%s" doesn\"t match the expected class "%s"~ ";
                    myErrorMessage .= "You can\"t have an association of the same name with a different target ";
                    myErrorMessage .= ""className" option anywhere in your app.";

                    throw new RuntimeException(sprintf(
                        myErrorMessage,
                        _sourceTable is null ? "null" : get_class(_sourceTable),
                        this.getName(),
                        this.type(),
                        get_class(_targetTable),
                        myClassName
                    ));
                }
            }
        }

        return _targetTable;
    }

    /**
     * Sets a list of conditions to be always included when fetching records from
     * the target association.
     *
     * @param \Closure|array $conditions list of conditions to be used
     * @see uim.cake.databases.Query::where() for examples on the format of the array
     * @return uim.cake.orm.Association
     */
    auto setConditions($conditions) {
        _conditions = $conditions;

        return this;
    }

    /**
     * Gets a list of conditions to be always included when fetching records from
     * the target association.
     *
     * @see uim.cake.databases.Query::where() for examples on the format of the array
     * @return \Closure|array
     */
    auto getConditions() {
        return _conditions;
    }

    /**
     * Sets the name of the field representing the binding field with the target table.
     * When not manually specified the primary key of the owning side table is used.
     *
     * @param array<string>|string myKey the table field or fields to be used to link both tables together
     * @return this
     */
    auto setBindingKey(myKey) {
        _bindingKey = myKey;

        return this;
    }

    /**
     * Gets the name of the field representing the binding field with the target table.
     * When not manually specified the primary key of the owning side table is used.
     */
    string[] getBindingKey() {
        if (_bindingKey is null) {
            _bindingKey = this.isOwningSide(this.getSource()) ?
                this.getSource().getPrimaryKey() :
                this.getTarget().getPrimaryKey();
        }

        return _bindingKey;
    }

    // Gets the name of the field representing the foreign key to the target table.
    string[] getForeignKey() {
        return _foreignKey;
    }

    /**
     * Sets the name of the field representing the foreign key to the target table.
     *
     * @param myKey the key or keys to be used to link both tables together
     * @return this
     */
    auto setForeignKey(string[] myKey) {
        _foreignKey = myKey;

        return this;
    }

    /**
     * Sets whether the records on the target table are dependent on the source table.
     *
     * This is primarily used to indicate that records should be removed if the owning record in
     * the source table is deleted.
     *
     * If no parameters are passed the current setting is returned.
     *
     * @param bool $dependent Set the dependent mode. Use null to read the current state.
     * @return this
     */
    auto setDependent(bool $dependent) {
        _dependent = $dependent;

        return this;
    }

    /**
     * Sets whether the records on the target table are dependent on the source table.
     *
     * This is primarily used to indicate that records should be removed if the owning record in
     * the source table is deleted.
     */
    bool getDependent() {
        return _dependent;
    }

    /**
     * Whether this association can be expressed directly in a query join
     *
     * @param array<string, mixed> myOptions custom options key that could alter the return value
     */
    bool canBeJoined(array myOptions = []) {
        $strategy = myOptions["strategy"] ?? this.getStrategy();

        return $strategy == this::STRATEGY_JOIN;
    }

    /**
     * Sets the type of join to be used when adding the association to a query.
     *
     * @param string myType the join type to be used (e.g. INNER)
     * @return this
     */
    auto setJoinType(string myType) {
        _joinType = myType;

        return this;
    }

    /**
     * Gets the type of join to be used when adding the association to a query.
     */
    string getJoinType() {
        return _joinType;
    }

    /**
     * Sets the property name that should be filled with data from the target table
     * in the source table record.
     *
     * @param string myName The name of the association property. Use null to read the current value.
     * @return this
     */
    auto setProperty(string myName) {
        _propertyName = myName;

        return this;
    }

    /**
     * Gets the property name that should be filled with data from the target table
     * in the source table record.
     */
    string getProperty() {
        if (!_propertyName) {
            _propertyName = _propertyName();
            if (in_array(_propertyName, _sourceTable.getSchema().columns(), true)) {
                $msg = "Association property name "%s" clashes with field of same name of table "%s"." ~
                    " You should explicitly specify the "propertyName" option.";
                trigger_error(
                    sprintf($msg, _propertyName, _sourceTable.getTable()),
                    E_USER_WARNING
                );
            }
        }

        return _propertyName;
    }

    /**
     * Returns default property name based on association name.
     */
    protected string _propertyName() {
        [, myName] = pluginSplit(_name);

        return Inflector::underscore(myName);
    }

    /**
     * Sets the strategy name to be used to fetch associated records. Keep in mind
     * that some association types might not implement but a default strategy,
     * rendering any changes to this setting void.
     *
     * @param string myName The strategy type. Use null to read the current value.
     * @return this
     * @throws \InvalidArgumentException When an invalid strategy is provided.
     */
    auto setStrategy(string myName) {
        if (!in_array(myName, _validStrategies, true)) {
            throw new InvalidArgumentException(sprintf(
                "Invalid strategy "%s" was provided. Valid options are (%s).",
                myName,
                implode(", ", _validStrategies)
            ));
        }
        _strategy = myName;

        return this;
    }

    /**
     * Gets the strategy name to be used to fetch associated records. Keep in mind
     * that some association types might not implement but a default strategy,
     * rendering any changes to this setting void.
     */
    string getStrategy() {
        return _strategy;
    }

    /**
     * Gets the default finder to use for fetching rows from the target table.
     *
     * @return array|string
     */
    auto getFinder() {
        return _finder;
    }

    /**
     * Sets the default finder to use for fetching rows from the target table.
     *
     * @param array|string myFinder the finder name to use or array of finder name and option.
     * @return this
     */
    auto setFinder(myFinder) {
        _finder = myFinder;

        return this;
    }

    /**
     * Override this function to initialize any concrete association class, it will
     * get passed the original list of options used in the constructor
     *
     * @param array<string, mixed> myOptions List of options used for initialization
     */
    protected void _options(array myOptions) {
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
     * - conditions: array with a list of conditions to filter the join with, this
     *   will be merged with any conditions originally configured for this association
     * - fields: a list of fields in the target table to include in the result
     * - aliasPath: A dot separated string representing the path of association names
     *   followed from the passed query main table to this association.
     * - propertyPath: A dot separated string representing the path of association
     *   properties to be followed from the passed query main entity to this
     *   association
     * - joinType: The SQL join type to use in the query.
     * - negateMatch: Will append a condition to the passed query for excluding matches.
     *   with this association.
     *
     * @param uim.cake.orm.Query myQuery the query to be altered to include the target table data
     * @param array<string, mixed> myOptions Any extra options or overrides to be taken in account
     * @return void
     * @throws \RuntimeException Unable to build the query or associations.
     */
    void attachTo(Query myQuery, array myOptions = []) {
        myTarget = this.getTarget();
        myTable = myTarget.getTable();

        myOptions += [
            "includeFields":true,
            "foreignKey":this.getForeignKey(),
            "conditions":[],
            "joinType":this.getJoinType(),
            "fields":[],
            "table":myTable,
            "finder":this.getFinder(),
        ];

        // This is set by joinWith to disable matching results
        if (myOptions["fields"] == false) {
            myOptions["fields"] = [];
            myOptions["includeFields"] = false;
        }

        if (!empty(myOptions["foreignKey"])) {
            $joinCondition = _joinCondition(myOptions);
            if ($joinCondition) {
                myOptions["conditions"][] = $joinCondition;
            }
        }

        [myFinder, $opts] = _extractFinder(myOptions["finder"]);
        $dummy = this
            .find(myFinder, $opts)
            .eagerLoaded(true);

        if (!empty(myOptions["queryBuilder"])) {
            $dummy = myOptions["queryBuilder"]($dummy);
            if (!($dummy instanceof Query)) {
                throw new RuntimeException(sprintf(
                    "Query builder for association "%s" did not return a query",
                    this.getName()
                ));
            }
        }

        if (
            !empty(myOptions["matching"]) &&
            _strategy == static::STRATEGY_JOIN &&
            $dummy.getContain()
        ) {
            throw new RuntimeException(
                "`{this.getName()}` association cannot contain() associations when using JOIN strategy."
            );
        }

        $dummy.where(myOptions["conditions"]);
        _dispatchBeforeFind($dummy);

        myQuery.join([_name: [
            "table":myOptions["table"],
            "conditions":$dummy.clause("where"),
            "type":myOptions["joinType"],
        ]]);

        _appendFields(myQuery, $dummy, myOptions);
        _formatAssociationResults(myQuery, $dummy, myOptions);
        _bindNewAssociations(myQuery, $dummy, myOptions);
        _appendNotMatching(myQuery, myOptions);
    }

    /**
     * Conditionally adds a condition to the passed Query that will make it find
     * records where there is no match with this association.
     *
     * @param uim.cake.orm.Query myQuery The query to modify
     * @param array<string, mixed> myOptions Options array containing the `negateMatch` key.
     */
    protected void _appendNotMatching(Query myQuery, array myOptions) {
        myTarget = _targetTable;
        if (!empty(myOptions["negateMatch"])) {
            $primaryKey = myQuery.aliasFields((array)myTarget.getPrimaryKey(), _name);
            myQuery.andWhere(function ($exp) use ($primaryKey) {
                array_map([$exp, "isNull"], $primaryKey);

                return $exp;
            });
        }
    }

    /**
     * Correctly nests a result row associated values into the correct array keys inside the
     * source results.
     *
     * @param array $row The row to transform
     * @param string nestKey The array key under which the results for this association
     *   should be found
     * @param bool $joined Whether the row is a result of a direct join
     *   with this association
     * @param string|null myTargetProperty The property name in the source results where the association
     * data shuld be nested in. Will use the default one if not provided.
     * @return array
     */
    array transformRow(array $row, string nestKey, bool $joined, Nullable!string myTargetProperty = null) {
        $sourceAlias = this.getSource().getAlias();
        $nestKey = $nestKey ?: _name;
        myTargetProperty = myTargetProperty ?: this.getProperty();
        if (isset($row[$sourceAlias])) {
            $row[$sourceAlias][myTargetProperty] = $row[$nestKey];
            unset($row[$nestKey]);
        }

        return $row;
    }

    /**
     * Returns a modified row after appending a property for this association
     * with the default empty value according to whether the association was
     * joined or fetched externally.
     *
     * @param array $row The row to set a default on.
     * @param bool $joined Whether the row is a result of a direct join
     *   with this association
     * @return array
     */
    array defaultRowValue(array $row, bool $joined) {
        $sourceAlias = this.getSource().getAlias();
        if (isset($row[$sourceAlias])) {
            $row[$sourceAlias][this.getProperty()] = null;
        }

        return $row;
    }

    /**
     * Proxies the finding operation to the target table"s find method
     * and modifies the query accordingly based of this association
     * configuration
     *
     * @param array<string, mixed>|string|null myType the type of query to perform, if an array is passed,
     *   it will be interpreted as the `myOptions` parameter
     * @param array<string, mixed> myOptions The options to for the find
     * @see uim.cake.orm.Table::find()
     * @return uim.cake.orm.Query
     */
    function find(myType = null, array myOptions = []): Query
    {
        myType = myType ?: this.getFinder();
        [myType, $opts] = _extractFinder(myType);

        return this.getTarget()
            .find(myType, myOptions + $opts)
            .where(this.getConditions());
    }

    /**
     * Proxies the operation to the target table"s exists method after
     * appending the default conditions for this association
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string|null $conditions The conditions to use
     * for checking if any record matches.
     * @see uim.cake.orm.Table::exists()
     */
    bool exists($conditions) {
        $conditions = this.find()
            .where($conditions)
            .clause("where");

        return this.getTarget().exists($conditions);
    }

    /**
     * Proxies the update operation to the target table"s updateAll method
     *
     * @param array myFields A hash of field: new value.
     * @param uim.cake.databases.IExpression|\Closure|array|string|null $conditions Conditions to be used, accepts anything Query::where()
     * can take.
     * @see uim.cake.orm.Table::updateAll()
     * @return int Count Returns the affected rows.
     */
    int updateAll(array myFields, $conditions) {
        $expression = this.find()
            .where($conditions)
            .clause("where");

        return this.getTarget().updateAll(myFields, $expression);
    }

    /**
     * Proxies the delete operation to the target table"s deleteAll method
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string|null $conditions Conditions to be used, accepts anything Query::where()
     * can take.
     * @return int Returns the number of affected rows.
     * @see uim.cake.orm.Table::deleteAll()
     */
    int deleteAll($conditions) {
        $expression = this.find()
            .where($conditions)
            .clause("where");

        return this.getTarget().deleteAll($expression);
    }

    /**
     * Returns true if the eager loading process will require a set of the owning table"s
     * binding keys in order to use them as a filter in the finder query.
     *
     * @param array<string, mixed> myOptions The options containing the strategy to be used.
     * @return bool true if a list of keys will be required
     */
    bool requiresKeys(array myOptions = []) {
        $strategy = myOptions["strategy"] ?? this.getStrategy();

        return $strategy == static::STRATEGY_SELECT;
    }

    /**
     * Triggers beforeFind on the target table for the query this association is
     * attaching to
     *
     * @param uim.cake.orm.Query myQuery the query this association is attaching itself to
     */
    protected void _dispatchBeforeFind(Query myQuery) {
        myQuery.triggerBeforeFind();
    }

    /**
     * Helper function used to conditionally append fields to the select clause of
     * a query from the fields found in another query object.
     *
     * @param uim.cake.orm.Query myQuery the query that will get the fields appended to
     * @param uim.cake.orm.Query $surrogate the query having the fields to be copied from
     * @param array<string, mixed> myOptions options passed to the method `attachTo`
     */
    protected void _appendFields(Query myQuery, Query $surrogate, array myOptions) {
        if (myQuery.getEagerLoader().isAutoFieldsEnabled() == false) {
            return;
        }

        myFields = array_merge($surrogate.clause("select"), myOptions["fields"]);

        if (
            (empty(myFields) && myOptions["includeFields"]) ||
            $surrogate.isAutoFieldsEnabled()
        ) {
            myFields = array_merge(myFields, _targetTable.getSchema().columns());
        }

        myQuery.select(myQuery.aliasFields(myFields, _name));
        myQuery.addDefaultTypes(_targetTable);
    }

    /**
     * Adds a formatter function to the passed `myQuery` if the `$surrogate` query
     * declares any other formatter. Since the `$surrogate` query correspond to
     * the associated target table, the resulting formatter will be the result of
     * applying the surrogate formatters to only the property corresponding to
     * such table.
     *
     * @param uim.cake.orm.Query myQuery the query that will get the formatter applied to
     * @param uim.cake.orm.Query $surrogate the query having formatters for the associated
     * target table.
     * @param array<string, mixed> myOptions options passed to the method `attachTo`
     */
    protected void _formatAssociationResults(Query myQuery, Query $surrogate, array myOptions) {
        $formatters = $surrogate.getResultFormatters();

        if (!$formatters || empty(myOptions["propertyPath"])) {
            return;
        }

        $property = myOptions["propertyPath"];
        $propertyPath = explode(".", $property);
        myQuery.formatResults(function (myResults, myQuery) use ($formatters, $property, $propertyPath) {
            $extracted = [];
            foreach (myResults as myResult) {
                foreach ($propertyPath as $propertyPathItem) {
                    if (!isset(myResult[$propertyPathItem])) {
                        myResult = null;
                        break;
                    }
                    myResult = myResult[$propertyPathItem];
                }
                $extracted[] = myResult;
            }
            $extracted = new Collection($extracted);
            foreach ($formatters as $callable) {
                $extracted = new ResultSetDecorator($callable($extracted, myQuery));
            }

            /** @var uim.cake.collections.ICollection myResults */
            myResults = myResults.insert($property, $extracted);
            if (myQuery.isHydrationEnabled()) {
                myResults = myResults.map(function (myResult) {
                    myResult.clean();

                    return myResult;
                });
            }

            return myResults;
        }, Query::PREPEND);
    }

    /**
     * Applies all attachable associations to `myQuery` out of the containments found
     * in the `$surrogate` query.
     *
     * Copies all contained associations from the `$surrogate` query into the
     * passed `myQuery`. Containments are altered so that they respect the associations
     * chain from which they originated.
     *
     * @param uim.cake.orm.Query myQuery the query that will get the associations attached to
     * @param uim.cake.orm.Query $surrogate the query having the containments to be attached
     * @param array<string, mixed> myOptions options passed to the method `attachTo`
     */
    protected void _bindNewAssociations(Query myQuery, Query $surrogate, array myOptions) {
        $loader = $surrogate.getEagerLoader();
        $contain = $loader.getContain();
        $matching = $loader.getMatching();

        if (!$contain && !$matching) {
            return;
        }

        $newContain = [];
        foreach ($contain as myAlias: myValue) {
            $newContain[myOptions["aliasPath"] ~ "." ~ myAlias] = myValue;
        }

        $eagerLoader = myQuery.getEagerLoader();
        if ($newContain) {
            $eagerLoader.contain($newContain);
        }

        foreach ($matching as myAlias: myValue) {
            $eagerLoader.setMatching(
                myOptions["aliasPath"] ~ "." ~ myAlias,
                myValue["queryBuilder"],
                myValue
            );
        }
    }

    /**
     * Returns a single or multiple conditions to be appended to the generated join
     * clause for getting the results on the target table.
     *
     * @param array<string, mixed> myOptions list of options passed to attachTo method
     * @return array
     * @throws \RuntimeException if the number of columns in the foreignKey do not
     * match the number of columns in the source table primaryKey
     */
    protected array _joinCondition(array myOptions) {
        $conditions = [];
        $tAlias = _name;
        $sAlias = this.getSource().getAlias();
        $foreignKey = (array)myOptions["foreignKey"];
        $bindingKey = (array)this.getBindingKey();

        if (count($foreignKey) != count($bindingKey)) {
            if (empty($bindingKey)) {
                myTable = this.getTarget().getTable();
                if (this.isOwningSide(this.getSource())) {
                    myTable = this.getSource().getTable();
                }
                $msg = "The "%s" table does not define a primary key, and cannot have join conditions generated.";
                throw new RuntimeException(sprintf($msg, myTable));
            }

            $msg = "Cannot match provided foreignKey for "%s", got "(%s)" but expected foreign key for "(%s)"";
            throw new RuntimeException(sprintf(
                $msg,
                _name,
                implode(", ", $foreignKey),
                implode(", ", $bindingKey)
            ));
        }

        foreach ($foreignKey as $k: $f) {
            myField = sprintf("%s.%s", $sAlias, $bindingKey[$k]);
            myValue = new IdentifierExpression(sprintf("%s.%s", $tAlias, $f));
            $conditions[myField] = myValue;
        }

        return $conditions;
    }

    /**
     * Helper method to infer the requested finder and its options.
     *
     * Returns the inferred options from the finder myType.
     *
     * ### Examples:
     *
     * The following will call the finder "translations" with the value of the finder as its options:
     * myQuery.contain(["Comments":["finder":["translations"]]]);
     * myQuery.contain(["Comments":["finder":["translations":[]]]]);
     * myQuery.contain(["Comments":["finder":["translations":["locales":["en_US"]]]]]);
     *
     * @param array|string myFinderData The finder name or an array having the name as key
     * and options as value.
     * @return array
     */
    protected array _extractFinder(myFinderData) {
        myFinderData = (array)myFinderData;

        if (is_numeric(key(myFinderData))) {
            return [current(myFinderData), []];
        }

        return [key(myFinderData), current(myFinderData)];
    }

    /**
     * Proxies property retrieval to the target table. This is handy for getting this
     * association"s associations
     *
     * @param string property the property name
     * @return uim.cake.orm.Association
     * @throws \RuntimeException if no association with such name exists
     */
    auto __get($property) {
        return this.getTarget().{$property};
    }

    /**
     * Proxies the isset call to the target table. This is handy to check if the
     * target table has another association with the passed name
     *
     * @param string property the property name
     * @return bool true if the property exists
     */
    auto __isSet($property) {
        return isset(this.getTarget().{$property});
    }

    /**
     * Proxies method calls to the target table.
     *
     * @param string method name of the method to be invoked
     * @param array $argument List of arguments passed to the function
     * @return mixed
     * @throws \BadMethodCallException
     */
    auto __call($method, $argument) {
        return this.getTarget().$method(...$argument);
    }

    /**
     * Get the relationship type.
     *
     * @return string Constant of either ONE_TO_ONE, MANY_TO_ONE, ONE_TO_MANY or MANY_TO_MANY.
     */
    abstract string type();

    /**
     * Eager loads a list of records in the target table that are related to another
     * set of records in the source table. Source records can be specified in two ways:
     * first one is by passing a Query object setup to find on the source table and
     * the other way is by explicitly passing an array of primary key values from
     * the source table.
     *
     * The required way of passing related source records is controlled by "strategy"
     * When the subquery strategy is used it will require a query on the source table.
     * When using the select strategy, the list of primary keys will be used.
     *
     * Returns a closure that should be run for each record returned in a specific
     * Query. This callable will be responsible for injecting the fields that are
     * related to each specific passed row.
     *
     * Options array accepts the following keys:
     *
     * - query: Query object setup to find the source table records
     * - keys: List of primary key values from the source table
     * - foreignKey: The name of the field used to relate both tables
     * - conditions: List of conditions to be passed to the query where() method
     * - sort: The direction in which the records should be returned
     * - fields: List of fields to select from the target table
     * - contain: List of related tables to eager load associated to the target table
     * - strategy: The name of strategy to use for finding target table records
     * - nestKey: The array key under which results will be found when transforming the row
     *
     * @param array<string, mixed> myOptions The options for eager loading.
     * @return \Closure
     */
    abstract Closure eagerLoader(array myOptions);

    /**
     * Handles cascading a delete from an associated model.
     *
     * Each implementing class should handle the cascaded delete as
     * required.
     *
     * @param uim.cake.Datasource\IEntity $entity The entity that started the cascaded delete.
     * @param array<string, mixed> myOptions The options for the original delete.
     * @return bool Success
     */
    abstract bool cascadeDelete(IEntity $entity, array myOptions = []);

    /**
     * Returns whether the passed table is the owning side for this
     * association. This means that rows in the "target" table would miss important
     * or required information if the row in "source" did not exist.
     *
     * @param uim.cake.orm.Table $side The potential Table with ownership
     * @return bool
     */
    abstract bool isOwningSide(Table $side);

    /**
     * Extract the target"s association data our from the passed entity and proxies
     * the saving operation to the target table.
     *
     * @param uim.cake.Datasource\IEntity $entity the data to be saved
     * @param array<string, mixed> myOptions The options for saving associated data.
     * @return uim.cake.Datasource\IEntity|false false if $entity could not be saved, otherwise it returns
     * the saved entity
     * @see uim.cake.orm.Table::save()
     */
    abstract function saveAssociated(IEntity $entity, array myOptions = []);
}
