module uim.cake.orm.Association\Loader;

import uim.cake.databases.expressions\IdentifierExpression;
import uim.cake.databases.expressions\TupleComparison;
import uim.cake.databases.ValueBinder;
import uim.cake.orm.Association;
import uim.cake.orm.Query;
use Closure;
use InvalidArgumentException;
use RuntimeException;

/**
 * : the logic for loading an association using a SELECT query
 *
 * @internal
 */
class SelectLoader
{
    /**
     * The alias of the association loading the results
     *
     * @var string
     */
    protected myAlias;

    /**
     * The alias of the source association
     *
     * @var string
     */
    protected $sourceAlias;

    /**
     * The alias of the target association
     *
     * @var string
     */
    protected myTargetAlias;

    /**
     * The foreignKey to the target association
     *
     * @var array|string
     */
    protected $foreignKey;

    /**
     * The strategy to use for loading, either select or subquery
     *
     * @var string
     */
    protected $strategy;

    /**
     * The binding key for the source association.
     *
     * @var string
     */
    protected $bindingKey;

    /**
     * A callable that will return a query object used for loading the association results
     *
     * @var callable
     */
    protected myFinder;

    /**
     * The type of the association triggering the load
     *
     * @var string
     */
    protected $associationType;

    /**
     * The sorting options for loading the association
     *
     * @var string
     */
    protected $sort;

    /**
     * Copies the options array to properties in this class. The keys in the array correspond
     * to properties in this class.
     *
     * @param array<string, mixed> myOptions Properties to be copied to this class
     */
    this(array myOptions) {
        this.alias = myOptions['alias'];
        this.sourceAlias = myOptions['sourceAlias'];
        this.targetAlias = myOptions['targetAlias'];
        this.foreignKey = myOptions['foreignKey'];
        this.strategy = myOptions['strategy'];
        this.bindingKey = myOptions['bindingKey'];
        this.finder = myOptions['finder'];
        this.associationType = myOptions['associationType'];
        this.sort = myOptions['sort'] ?? null;
    }

    /**
     * Returns a callable that can be used for injecting association results into a given
     * iterator. The options accepted by this method are the same as `Association::eagerLoader()`
     *
     * @param array<string, mixed> myOptions Same options as `Association::eagerLoader()`
     * @return \Closure
     */
    function buildEagerLoader(array myOptions): Closure
    {
        myOptions += this._defaultOptions();
        $fetchQuery = this._buildQuery(myOptions);
        myResultMap = this._buildResultMap($fetchQuery, myOptions);

        return this._resultInjector($fetchQuery, myResultMap, myOptions);
    }

    /**
     * Returns the default options to use for the eagerLoader
     *
     * @return array
     */
    protected auto _defaultOptions(): array
    {
        return [
            'foreignKey' => this.foreignKey,
            'conditions' => [],
            'strategy' => this.strategy,
            'nestKey' => this.alias,
            'sort' => this.sort,
        ];
    }

    /**
     * Auxiliary function to construct a new Query object to return all the records
     * in the target table that are associated to those specified in myOptions from
     * the source table
     *
     * @param array<string, mixed> myOptions options accepted by eagerLoader()
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException When a key is required for associations but not selected.
     */
    protected auto _buildQuery(array myOptions): Query
    {
        myKey = this._linkField(myOptions);
        $filter = myOptions['keys'];
        $useSubquery = myOptions['strategy'] === Association::STRATEGY_SUBQUERY;
        myFinder = this.finder;
        myOptions['fields'] = myOptions['fields'] ?? [];

        /** @var \Cake\ORM\Query myQuery */
        myQuery = myFinder();
        if (isset(myOptions['finder'])) {
            [myFinderName, $opts] = this._extractFinder(myOptions['finder']);
            myQuery = myQuery.find(myFinderName, $opts);
        }

        $fetchQuery = myQuery
            .select(myOptions['fields'])
            .where(myOptions['conditions'])
            .eagerLoaded(true)
            .enableHydration(myOptions['query'].isHydrationEnabled());
        if (myOptions['query'].isResultsCastingEnabled()) {
            $fetchQuery.enableResultsCasting();
        } else {
            $fetchQuery.disableResultsCasting();
        }

        if ($useSubquery) {
            $filter = this._buildSubquery(myOptions['query']);
            $fetchQuery = this._addFilteringJoin($fetchQuery, myKey, $filter);
        } else {
            $fetchQuery = this._addFilteringCondition($fetchQuery, myKey, $filter);
        }

        if (!empty(myOptions['sort'])) {
            $fetchQuery.order(myOptions['sort']);
        }

        if (!empty(myOptions['contain'])) {
            $fetchQuery.contain(myOptions['contain']);
        }

        if (!empty(myOptions['queryBuilder'])) {
            $fetchQuery = myOptions['queryBuilder']($fetchQuery);
        }

        this._assertFieldsPresent($fetchQuery, (array)myKey);

        return $fetchQuery;
    }

    /**
     * Helper method to infer the requested finder and its options.
     *
     * Returns the inferred options from the finder myType.
     *
     * ### Examples:
     *
     * The following will call the finder 'translations' with the value of the finder as its options:
     * myQuery.contain(['Comments' => ['finder' => ['translations']]]);
     * myQuery.contain(['Comments' => ['finder' => ['translations' => []]]]);
     * myQuery.contain(['Comments' => ['finder' => ['translations' => ['locales' => ['en_US']]]]]);
     *
     * @param array|string myFinderData The finder name or an array having the name as key
     * and options as value.
     * @return array
     */
    protected auto _extractFinder(myFinderData): array
    {
        myFinderData = (array)myFinderData;

        if (is_numeric(key(myFinderData))) {
            return [current(myFinderData), []];
        }

        return [key(myFinderData), current(myFinderData)];
    }

    /**
     * Checks that the fetching query either has auto fields on or
     * has the foreignKey fields selected.
     * If the required fields are missing, throws an exception.
     *
     * @param \Cake\ORM\Query $fetchQuery The association fetching query
     * @param array<string> myKey The foreign key fields to check
     * @return void
     * @throws \InvalidArgumentException
     */
    protected auto _assertFieldsPresent(Query $fetchQuery, array myKey): void
    {
        $select = $fetchQuery.aliasFields($fetchQuery.clause('select'));
        if (empty($select)) {
            return;
        }
        $missingKey = function (myFieldList, myKey) {
            foreach (myKey as myKeyField) {
                if (!in_array(myKeyField, myFieldList, true)) {
                    return true;
                }
            }

            return false;
        };

        $missingFields = $missingKey($select, myKey);
        if ($missingFields) {
            myDriver = $fetchQuery.getConnection().getDriver();
            $quoted = array_map([myDriver, 'quoteIdentifier'], myKey);
            $missingFields = $missingKey($select, $quoted);
        }

        if ($missingFields) {
            throw new InvalidArgumentException(
                sprintf(
                    'You are required to select the "%s" field(s)',
                    implode(', ', myKey)
                )
            );
        }
    }

    /**
     * Appends any conditions required to load the relevant set of records in the
     * target table query given a filter key and some filtering values when the
     * filtering needs to be done using a subquery.
     *
     * @param \Cake\ORM\Query myQuery Target table's query
     * @param array<string>|string myKey the fields that should be used for filtering
     * @param \Cake\ORM\Query $subquery The Subquery to use for filtering
     * @return \Cake\ORM\Query
     */
    protected auto _addFilteringJoin(Query myQuery, myKey, $subquery): Query
    {
        $filter = [];
        myAliasedTable = this.sourceAlias;

        foreach ($subquery.clause('select') as myAliasedField => myField) {
            if (is_int(myAliasedField)) {
                $filter[] = new IdentifierExpression(myField);
            } else {
                $filter[myAliasedField] = myField;
            }
        }
        $subquery.select($filter, true);

        if (is_array(myKey)) {
            $conditions = this._createTupleCondition(myQuery, myKey, $filter, '=');
        } else {
            $filter = current($filter);
            $conditions = myQuery.newExpr([myKey => $filter]);
        }

        return myQuery.innerJoin(
            [myAliasedTable => $subquery],
            $conditions
        );
    }

    /**
     * Appends any conditions required to load the relevant set of records in the
     * target table query given a filter key and some filtering values.
     *
     * @param \Cake\ORM\Query myQuery Target table's query
     * @param array<string>|string myKey The fields that should be used for filtering
     * @param mixed $filter The value that should be used to match for myKey
     * @return \Cake\ORM\Query
     */
    protected auto _addFilteringCondition(Query myQuery, myKey, $filter): Query
    {
        if (is_array(myKey)) {
            $conditions = this._createTupleCondition(myQuery, myKey, $filter, 'IN');
        } else {
            $conditions = [myKey . ' IN' => $filter];
        }

        return myQuery.andWhere($conditions);
    }

    /**
     * Returns a TupleComparison object that can be used for matching all the fields
     * from myKeys with the tuple values in $filter using the provided operator.
     *
     * @param \Cake\ORM\Query myQuery Target table's query
     * @param array<string> myKeys the fields that should be used for filtering
     * @param mixed $filter the value that should be used to match for myKey
     * @param string $operator The operator for comparing the tuples
     * @return \Cake\Database\Expression\TupleComparison
     */
    protected auto _createTupleCondition(Query myQuery, array myKeys, $filter, $operator): TupleComparison
    {
        myTypes = [];
        $defaults = myQuery.getDefaultTypes();
        foreach (myKeys as $k) {
            if (isset($defaults[$k])) {
                myTypes[] = $defaults[$k];
            }
        }

        return new TupleComparison(myKeys, $filter, myTypes, $operator);
    }

    /**
     * Generates a string used as a table field that contains the values upon
     * which the filter should be applied
     *
     * @param array<string, mixed> myOptions The options for getting the link field.
     * @return array<string>|string
     * @throws \RuntimeException
     */
    protected auto _linkField(array myOptions) {
        $links = [];
        myName = this.alias;

        if (myOptions['foreignKey'] === false && this.associationType === Association::ONE_TO_MANY) {
            $msg = 'Cannot have foreignKey = false for hasMany associations. ' .
                   'You must provide a foreignKey column.';
            throw new RuntimeException($msg);
        }

        myKeys = in_array(this.associationType, [Association::ONE_TO_ONE, Association::ONE_TO_MANY], true) ?
            this.foreignKey :
            this.bindingKey;

        foreach ((array)myKeys as myKey) {
            $links[] = sprintf('%s.%s', myName, myKey);
        }

        if (count($links) === 1) {
            return $links[0];
        }

        return $links;
    }

    /**
     * Builds a query to be used as a condition for filtering records in the
     * target table, it is constructed by cloning the original query that was used
     * to load records in the source table.
     *
     * @param \Cake\ORM\Query myQuery the original query used to load source records
     * @return \Cake\ORM\Query
     */
    protected auto _buildSubquery(Query myQuery): Query
    {
        $filterQuery = clone myQuery;
        $filterQuery.disableAutoFields();
        $filterQuery.mapReduce(null, null, true);
        $filterQuery.formatResults(null, true);
        $filterQuery.contain([], true);
        $filterQuery.setValueBinder(new ValueBinder());

        // Ignore limit if there is no order since we need all rows to find matches
        if (!$filterQuery.clause('limit') || !$filterQuery.clause('order')) {
            $filterQuery.limit(null);
            $filterQuery.order([], true);
            $filterQuery.offset(null);
        }

        myFields = this._subqueryFields(myQuery);
        $filterQuery.select(myFields['select'], true).group(myFields['group']);

        return $filterQuery;
    }

    /**
     * Calculate the fields that need to participate in a subquery.
     *
     * Normally this includes the binding key columns. If there is a an ORDER BY,
     * those columns are also included as the fields may be calculated or constant values,
     * that need to be present to ensure the correct association data is loaded.
     *
     * @param \Cake\ORM\Query myQuery The query to get fields from.
     * @return array<string, array> The list of fields for the subquery.
     */
    protected auto _subqueryFields(Query myQuery): array
    {
        myKeys = (array)this.bindingKey;

        if (this.associationType === Association::MANY_TO_ONE) {
            myKeys = (array)this.foreignKey;
        }

        myFields = myQuery.aliasFields(myKeys, this.sourceAlias);
        $group = myFields = array_values(myFields);

        $order = myQuery.clause('order');
        if ($order) {
            $columns = myQuery.clause('select');
            $order.iterateParts(function ($direction, myField) use (&myFields, $columns): void {
                if (isset($columns[myField])) {
                    myFields[myField] = $columns[myField];
                }
            });
        }

        return ['select' => myFields, 'group' => $group];
    }

    /**
     * Builds an array containing the results from fetchQuery indexed by
     * the foreignKey value corresponding to this association.
     *
     * @param \Cake\ORM\Query $fetchQuery The query to get results from
     * @param array<string, mixed> myOptions The options passed to the eager loader
     * @return array<string, mixed>
     */
    protected auto _buildResultMap(Query $fetchQuery, array myOptions): array
    {
        myResultMap = [];
        $singleResult = in_array(this.associationType, [Association::MANY_TO_ONE, Association::ONE_TO_ONE], true);
        myKeys = in_array(this.associationType, [Association::ONE_TO_ONE, Association::ONE_TO_MANY], true) ?
            this.foreignKey :
            this.bindingKey;
        myKey = (array)myKeys;

        foreach ($fetchQuery.all() as myResult) {
            myValues = [];
            foreach (myKey as $k) {
                myValues[] = myResult[$k];
            }
            if ($singleResult) {
                myResultMap[implode(';', myValues)] = myResult;
            } else {
                myResultMap[implode(';', myValues)][] = myResult;
            }
        }

        return myResultMap;
    }

    /**
     * Returns a callable to be used for each row in a query result set
     * for injecting the eager loaded rows
     *
     * @param \Cake\ORM\Query $fetchQuery the Query used to fetch results
     * @param array<string, mixed> myResultMap an array with the foreignKey as keys and
     * the corresponding target table results as value.
     * @param array<string, mixed> myOptions The options passed to the eagerLoader method
     * @return \Closure
     */
    protected auto _resultInjector(Query $fetchQuery, array myResultMap, array myOptions): Closure
    {
        myKeys = this.associationType === Association::MANY_TO_ONE ?
            this.foreignKey :
            this.bindingKey;

        $sourceKeys = [];
        foreach ((array)myKeys as myKey) {
            $f = $fetchQuery.aliasField(myKey, this.sourceAlias);
            $sourceKeys[] = key($f);
        }

        $nestKey = myOptions['nestKey'];
        if (count($sourceKeys) > 1) {
            return this._multiKeysInjector(myResultMap, $sourceKeys, $nestKey);
        }

        $sourceKey = $sourceKeys[0];

        return function ($row) use (myResultMap, $sourceKey, $nestKey) {
            if (isset($row[$sourceKey], myResultMap[$row[$sourceKey]])) {
                $row[$nestKey] = myResultMap[$row[$sourceKey]];
            }

            return $row;
        };
    }

    /**
     * Returns a callable to be used for each row in a query result set
     * for injecting the eager loaded rows when the matching needs to
     * be done with multiple foreign keys
     *
     * @param array<string, mixed> myResultMap A keyed arrays containing the target table
     * @param array<string> $sourceKeys An array with aliased keys to match
     * @param string $nestKey The key under which results should be nested
     * @return \Closure
     */
    protected auto _multiKeysInjector(array myResultMap, array $sourceKeys, string $nestKey): Closure
    {
        return function ($row) use (myResultMap, $sourceKeys, $nestKey) {
            myValues = [];
            foreach ($sourceKeys as myKey) {
                myValues[] = $row[myKey];
            }

            myKey = implode(';', myValues);
            if (isset(myResultMap[myKey])) {
                $row[$nestKey] = myResultMap[myKey];
            }

            return $row;
        };
    }
}
