module uim.baklava.ORM;

import uim.baklava.databases.Statement\BufferedStatement;
import uim.baklava.databases.Statement\CallbackStatement;
import uim.baklava.databases.IStatement;
use Closure;
use InvalidArgumentException;

/**
 * Exposes the methods for storing the associations that should be eager loaded
 * for a table once a query is provided and delegates the job of creating the
 * required joins and decorating the results so that those associations can be
 * part of the result set.
 */
class EagerLoader
{
    /**
     * Nested array describing the association to be fetched
     * and the options to apply for each of them, if any
     *
     * @var array<string, mixed>
     */
    protected $_containments = [];

    /**
     * Contains a nested array with the compiled containments tree
     * This is a normalized version of the user provided containments array.
     *
     * @var \Cake\ORM\EagerLoadable|array<\Cake\ORM\EagerLoadable>|null
     */
    protected $_normalized;

    /**
     * List of options accepted by associations in contain()
     * index by key for faster access
     *
     * @var array<string, int>
     */
    protected $_containOptions = [
        'associations' => 1,
        'foreignKey' => 1,
        'conditions' => 1,
        'fields' => 1,
        'sort' => 1,
        'matching' => 1,
        'queryBuilder' => 1,
        'finder' => 1,
        'joinType' => 1,
        'strategy' => 1,
        'negateMatch' => 1,
    ];

    /**
     * A list of associations that should be loaded with a separate query
     *
     * @var array<\Cake\ORM\EagerLoadable>
     */
    protected $_loadExternal = [];

    /**
     * Contains a list of the association names that are to be eagerly loaded
     *
     * @var array
     */
    protected $_aliasList = [];

    /**
     * Another EagerLoader instance that will be used for 'matching' associations.
     *
     * @var \Cake\ORM\EagerLoader|null
     */
    protected $_matching;

    /**
     * A map of table aliases pointing to the association objects they represent
     * for the query.
     *
     * @var array
     */
    protected $_joinsMap = [];

    /**
     * Controls whether fields from associated tables
     * will be eagerly loaded. When set to false, no fields will
     * be loaded from associations.
     *
     * @var bool
     */
    protected $_autoFields = true;

    /**
     * Sets the list of associations that should be eagerly loaded along for a
     * specific table using when a query is provided. The list of associated tables
     * passed to this method must have been previously set as associations using the
     * Table API.
     *
     * Associations can be arbitrarily nested using dot notation or nested arrays,
     * this allows this object to calculate joins or any additional queries that
     * must be executed to bring the required associated data.
     *
     * Accepted options per passed association:
     *
     * - foreignKey: Used to set a different field to match both tables, if set to false
     *   no join conditions will be generated automatically
     * - fields: An array with the fields that should be fetched from the association
     * - queryBuilder: Equivalent to passing a callable instead of an options array
     * - matching: Whether to inform the association class that it should filter the
     *  main query by the results fetched by that class.
     * - joinType: For joinable associations, the SQL join type to use.
     * - strategy: The loading strategy to use (join, select, subquery)
     *
     * @param array|string $associations list of table aliases to be queried.
     * When this method is called multiple times it will merge previous list with
     * the new one.
     * @param callable|null myQueryBuilder The query builder callable
     * @return array Containments.
     * @throws \InvalidArgumentException When using myQueryBuilder with an array of $associations
     */
    function contain($associations, ?callable myQueryBuilder = null): array
    {
        if (myQueryBuilder) {
            if (!is_string($associations)) {
                throw new InvalidArgumentException(
                    'Cannot set containments. To use myQueryBuilder, $associations must be a string'
                );
            }

            $associations = [
                $associations => [
                    'queryBuilder' => myQueryBuilder,
                ],
            ];
        }

        $associations = (array)$associations;
        $associations = this._reformatContain($associations, this._containments);
        this._normalized = null;
        this._loadExternal = [];
        this._aliasList = [];

        return this._containments = $associations;
    }

    /**
     * Gets the list of associations that should be eagerly loaded along for a
     * specific table using when a query is provided. The list of associated tables
     * passed to this method must have been previously set as associations using the
     * Table API.
     *
     * @return array Containments.
     */
    auto getContain(): array
    {
        return this._containments;
    }

    /**
     * Remove any existing non-matching based containments.
     *
     * This will reset/clear out any contained associations that were not
     * added via matching().
     *
     * @return void
     */
    function clearContain(): void
    {
        this._containments = [];
        this._normalized = null;
        this._loadExternal = [];
        this._aliasList = [];
    }

    /**
     * Sets whether contained associations will load fields automatically.
     *
     * @param bool myEnable The value to set.
     * @return this
     */
    function enableAutoFields(bool myEnable = true) {
        this._autoFields = myEnable;

        return this;
    }

    /**
     * Disable auto loading fields of contained associations.
     *
     * @return this
     */
    function disableAutoFields() {
        this._autoFields = false;

        return this;
    }

    /**
     * Gets whether contained associations will load fields automatically.
     *
     * @return bool The current value.
     */
    function isAutoFieldsEnabled(): bool
    {
        return this._autoFields;
    }

    /**
     * Adds a new association to the list that will be used to filter the results of
     * any given query based on the results of finding records for that association.
     * You can pass a dot separated path of associations to this method as its first
     * parameter, this will translate in setting all those associations with the
     * `matching` option.
     *
     *  ### Options
     *
     *  - `joinType`: INNER, OUTER, ...
     *  - `fields`: Fields to contain
     *  - `negateMatch`: Whether to add conditions negate match on target association
     *
     * @param string $associationPath Dot separated association path, 'Name1.Name2.Name3'
     * @param callable|null myBuilder the callback function to be used for setting extra
     * options to the filtering query
     * @param array<string, mixed> myOptions Extra options for the association matching.
     * @return this
     */
    auto setMatching(string $associationPath, ?callable myBuilder = null, array myOptions = []) {
        if (this._matching === null) {
            this._matching = new static();
        }

        myOptions += ['joinType' => Query::JOIN_TYPE_INNER];
        $sharedOptions = ['negateMatch' => false, 'matching' => true] + myOptions;

        $contains = [];
        $nested = &$contains;
        foreach (explode('.', $associationPath) as $association) {
            // Add contain to parent contain using association name as key
            $nested[$association] = $sharedOptions;
            // Set to next nested level
            $nested = &$nested[$association];
        }

        // Add all options to target association contain which is the last in nested chain
        $nested = ['matching' => true, 'queryBuilder' => myBuilder] + myOptions;
        this._matching.contain($contains);

        return this;
    }

    /**
     * Returns the current tree of associations to be matched.
     *
     * @return array The resulting containments array
     */
    auto getMatching(): array
    {
        if (this._matching === null) {
            this._matching = new static();
        }

        return this._matching.getContain();
    }

    /**
     * Returns the fully normalized array of associations that should be eagerly
     * loaded for a table. The normalized array will restructure the original array
     * by sorting all associations under one key and special options under another.
     *
     * Each of the levels of the associations tree will be converted to a {@link \Cake\ORM\EagerLoadable}
     * object, that contains all the information required for the association objects
     * to load the information from the database.
     *
     * Additionally, it will set an 'instance' key per association containing the
     * association instance from the corresponding source table
     *
     * @param \Cake\ORM\Table myRepository The table containing the association that
     * will be normalized
     * @return array
     */
    function normalized(Table myRepository): array
    {
        if (this._normalized !== null || empty(this._containments)) {
            return (array)this._normalized;
        }

        $contain = [];
        foreach (this._containments as myAlias => myOptions) {
            if (!empty(myOptions['instance'])) {
                $contain = this._containments;
                break;
            }
            $contain[myAlias] = this._normalizeContain(
                myRepository,
                myAlias,
                myOptions,
                ['root' => null]
            );
        }

        return this._normalized = $contain;
    }

    /**
     * Formats the containments array so that associations are always set as keys
     * in the array. This function merges the original associations array with
     * the new associations provided
     *
     * @param array $associations user provided containments array
     * @param array $original The original containments array to merge
     * with the new one
     * @return array
     */
    protected auto _reformatContain(array $associations, array $original): array
    {
        myResult = $original;

        foreach ($associations as myTable => myOptions) {
            $pointer = &myResult;
            if (is_int(myTable)) {
                myTable = myOptions;
                myOptions = [];
            }

            if (myOptions instanceof EagerLoadable) {
                myOptions = myOptions.asContainArray();
                myTable = key(myOptions);
                myOptions = current(myOptions);
            }

            if (isset(this._containOptions[myTable])) {
                $pointer[myTable] = myOptions;
                continue;
            }

            if (strpos(myTable, '.')) {
                myPath = explode('.', myTable);
                myTable = array_pop(myPath);
                foreach (myPath as $t) {
                    $pointer += [$t => []];
                    $pointer = &$pointer[$t];
                }
            }

            if (is_array(myOptions)) {
                myOptions = isset(myOptions['config']) ?
                    myOptions['config'] + myOptions['associations'] :
                    myOptions;
                myOptions = this._reformatContain(
                    myOptions,
                    $pointer[myTable] ?? []
                );
            }

            if (myOptions instanceof Closure) {
                myOptions = ['queryBuilder' => myOptions];
            }

            $pointer += [myTable => []];

            if (isset(myOptions['queryBuilder'], $pointer[myTable]['queryBuilder'])) {
                $first = $pointer[myTable]['queryBuilder'];
                $second = myOptions['queryBuilder'];
                myOptions['queryBuilder'] = function (myQuery) use ($first, $second) {
                    return $second($first(myQuery));
                };
            }

            if (!is_array(myOptions)) {
                /** @psalm-suppress InvalidArrayOffset */
                myOptions = [myOptions => []];
            }

            $pointer[myTable] = myOptions + $pointer[myTable];
        }

        return myResult;
    }

    /**
     * Modifies the passed query to apply joins or any other transformation required
     * in order to eager load the associations described in the `contain` array.
     * This method will not modify the query for loading external associations, i.e.
     * those that cannot be loaded without executing a separate query.
     *
     * @param \Cake\ORM\Query myQuery The query to be modified
     * @param \Cake\ORM\Table myRepository The repository containing the associations
     * @param bool $includeFields whether to append all fields from the associations
     * to the passed query. This can be overridden according to the settings defined
     * per association in the containments array
     * @return void
     */
    function attachAssociations(Query myQuery, Table myRepository, bool $includeFields): void
    {
        if (empty(this._containments) && this._matching === null) {
            return;
        }

        $attachable = this.attachableAssociations(myRepository);
        $processed = [];
        do {
            foreach ($attachable as myAlias => $loadable) {
                myConfig = $loadable.getConfig() + [
                    'aliasPath' => $loadable.aliasPath(),
                    'propertyPath' => $loadable.propertyPath(),
                    'includeFields' => $includeFields,
                ];
                $loadable.instance().attachTo(myQuery, myConfig);
                $processed[myAlias] = true;
            }

            $newAttachable = this.attachableAssociations(myRepository);
            $attachable = array_diff_key($newAttachable, $processed);
        } while (!empty($attachable));
    }

    /**
     * Returns an array with the associations that can be fetched using a single query,
     * the array keys are the association aliases and the values will contain an array
     * with Cake\ORM\EagerLoadable objects.
     *
     * @param \Cake\ORM\Table myRepository The table containing the associations to be
     * attached
     * @return array<\Cake\ORM\EagerLoadable>
     */
    function attachableAssociations(Table myRepository): array
    {
        $contain = this.normalized(myRepository);
        $matching = this._matching ? this._matching.normalized(myRepository) : [];
        this._fixStrategies();
        this._loadExternal = [];

        return this._resolveJoins($contain, $matching);
    }

    /**
     * Returns an array with the associations that need to be fetched using a
     * separate query, each array value will contain a {@link \Cake\ORM\EagerLoadable} object.
     *
     * @param \Cake\ORM\Table myRepository The table containing the associations
     * to be loaded
     * @return array<\Cake\ORM\EagerLoadable>
     */
    function externalAssociations(Table myRepository): array
    {
        if (this._loadExternal) {
            return this._loadExternal;
        }

        this.attachableAssociations(myRepository);

        return this._loadExternal;
    }

    /**
     * Auxiliary function responsible for fully normalizing deep associations defined
     * using `contain()`
     *
     * @param \Cake\ORM\Table $parent owning side of the association
     * @param string myAlias name of the association to be loaded
     * @param array<string, mixed> myOptions list of extra options to use for this association
     * @param array<string, mixed> myPaths An array with two values, the first one is a list of dot
     * separated strings representing associations that lead to this `myAlias` in the
     * chain of associations to be loaded. The second value is the path to follow in
     * entities' properties to fetch a record of the corresponding association.
     * @return \Cake\ORM\EagerLoadable Object with normalized associations
     * @throws \InvalidArgumentException When containments refer to associations that do not exist.
     */
    protected auto _normalizeContain(Table $parent, string myAlias, array myOptions, array myPaths): EagerLoadable
    {
        $defaults = this._containOptions;
        $instance = $parent.getAssociation(myAlias);

        myPaths += ['aliasPath' => '', 'propertyPath' => '', 'root' => myAlias];
        myPaths['aliasPath'] .= '.' . myAlias;

        if (
            isset(myOptions['matching']) &&
            myOptions['matching'] === true
        ) {
            myPaths['propertyPath'] = '_matchingData.' . myAlias;
        } else {
            myPaths['propertyPath'] .= '.' . $instance.getProperty();
        }

        myTable = $instance.getTarget();

        $extra = array_diff_key(myOptions, $defaults);
        myConfig = [
            'associations' => [],
            'instance' => $instance,
            'config' => array_diff_key(myOptions, $extra),
            'aliasPath' => trim(myPaths['aliasPath'], '.'),
            'propertyPath' => trim(myPaths['propertyPath'], '.'),
            'targetProperty' => $instance.getProperty(),
        ];
        myConfig['canBeJoined'] = $instance.canBeJoined(myConfig['config']);
        $eagerLoadable = new EagerLoadable(myAlias, myConfig);

        if (myConfig['canBeJoined']) {
            this._aliasList[myPaths['root']][myAlias][] = $eagerLoadable;
        } else {
            myPaths['root'] = myConfig['aliasPath'];
        }

        foreach ($extra as $t => $assoc) {
            $eagerLoadable.addAssociation(
                $t,
                this._normalizeContain(myTable, $t, $assoc, myPaths)
            );
        }

        return $eagerLoadable;
    }

    /**
     * Iterates over the joinable aliases list and corrects the fetching strategies
     * in order to avoid aliases collision in the generated queries.
     *
     * This function operates on the array references that were generated by the
     * _normalizeContain() function.
     *
     * @return void
     */
    protected auto _fixStrategies(): void
    {
        foreach (this._aliasList as myAliases) {
            foreach (myAliases as myConfigs) {
                if (count(myConfigs) < 2) {
                    continue;
                }
                /** @var \Cake\ORM\EagerLoadable $loadable */
                foreach (myConfigs as $loadable) {
                    if (strpos($loadable.aliasPath(), '.')) {
                        this._correctStrategy($loadable);
                    }
                }
            }
        }
    }

    /**
     * Changes the association fetching strategy if required because of duplicate
     * under the same direct associations chain
     *
     * @param \Cake\ORM\EagerLoadable $loadable The association config
     * @return void
     */
    protected auto _correctStrategy(EagerLoadable $loadable): void
    {
        myConfig = $loadable.getConfig();
        $currentStrategy = myConfig['strategy'] ??
            'join';

        if (!$loadable.canBeJoined() || $currentStrategy !== 'join') {
            return;
        }

        myConfig['strategy'] = Association::STRATEGY_SELECT;
        $loadable.setConfig(myConfig);
        $loadable.setCanBeJoined(false);
    }

    /**
     * Helper function used to compile a list of all associations that can be
     * joined in the query.
     *
     * @param array<\Cake\ORM\EagerLoadable> $associations list of associations from which to obtain joins.
     * @param array<\Cake\ORM\EagerLoadable> $matching list of associations that should be forcibly joined.
     * @return array<\Cake\ORM\EagerLoadable>
     */
    protected auto _resolveJoins(array $associations, array $matching = []): array
    {
        myResult = [];
        foreach ($matching as myTable => $loadable) {
            myResult[myTable] = $loadable;
            myResult += this._resolveJoins($loadable.associations(), []);
        }
        foreach ($associations as myTable => $loadable) {
            $inMatching = isset($matching[myTable]);
            if (!$inMatching && $loadable.canBeJoined()) {
                myResult[myTable] = $loadable;
                myResult += this._resolveJoins($loadable.associations(), []);
                continue;
            }

            if ($inMatching) {
                this._correctStrategy($loadable);
            }

            $loadable.setCanBeJoined(false);
            this._loadExternal[] = $loadable;
        }

        return myResult;
    }

    /**
     * Decorates the passed statement object in order to inject data from associations
     * that cannot be joined directly.
     *
     * @param \Cake\ORM\Query myQuery The query for which to eager load external
     * associations
     * @param \Cake\Database\IStatement $statement The statement created after executing the myQuery
     * @return \Cake\Database\IStatement statement modified statement with extra loaders
     * @throws \RuntimeException
     */
    function loadExternal(Query myQuery, IStatement $statement): IStatement
    {
        myTable = myQuery.getRepository();
        $external = this.externalAssociations(myTable);
        if (empty($external)) {
            return $statement;
        }

        myDriver = myQuery.getConnection().getDriver();
        [$collected, $statement] = this._collectKeys($external, myQuery, $statement);

        // No records found, skip trying to attach associations.
        if (empty($collected) && $statement.count() === 0) {
            return $statement;
        }

        foreach ($external as $meta) {
            $contain = $meta.associations();
            $instance = $meta.instance();
            myConfig = $meta.getConfig();
            myAlias = $instance.getSource().getAlias();
            myPath = $meta.aliasPath();

            $requiresKeys = $instance.requiresKeys(myConfig);
            if ($requiresKeys) {
                // If the path or alias has no key the required association load will fail.
                // Nested paths are not subject to this condition because they could
                // be attached to joined associations.
                if (
                    strpos(myPath, '.') === false &&
                    (!array_key_exists(myPath, $collected) || !array_key_exists(myAlias, $collected[myPath]))
                ) {
                    myMessage = "Unable to load `{myPath}` association. Ensure foreign key in `{myAlias}` is selected.";
                    throw new InvalidArgumentException(myMessage);
                }

                // If the association foreign keys are missing skip loading
                // as the association could be optional.
                if (empty($collected[myPath][myAlias])) {
                    continue;
                }
            }

            myKeys = $collected[myPath][myAlias] ?? null;
            $f = $instance.eagerLoader(
                myConfig + [
                    'query' => myQuery,
                    'contain' => $contain,
                    'keys' => myKeys,
                    'nestKey' => $meta.aliasPath(),
                ]
            );
            $statement = new CallbackStatement($statement, myDriver, $f);
        }

        return $statement;
    }

    /**
     * Returns an array having as keys a dotted path of associations that participate
     * in this eager loader. The values of the array will contain the following keys
     *
     * - alias: The association alias
     * - instance: The association instance
     * - canBeJoined: Whether the association will be loaded using a JOIN
     * - entityClass: The entity that should be used for hydrating the results
     * - nestKey: A dotted path that can be used to correctly insert the data into the results.
     * - matching: Whether it is an association loaded through `matching()`.
     *
     * @param \Cake\ORM\Table myTable The table containing the association that
     * will be normalized
     * @return array
     */
    function associationsMap(Table myTable): array
    {
        $map = [];

        if (!this.getMatching() && !this.getContain() && empty(this._joinsMap)) {
            return $map;
        }

        /** @psalm-suppress PossiblyNullReference */
        $map = this._buildAssociationsMap($map, this._matching.normalized(myTable), true);
        $map = this._buildAssociationsMap($map, this.normalized(myTable));
        $map = this._buildAssociationsMap($map, this._joinsMap);

        return $map;
    }

    /**
     * An internal method to build a map which is used for the return value of the
     * associationsMap() method.
     *
     * @param array $map An initial array for the map.
     * @param array<\Cake\ORM\EagerLoadable> $level An array of EagerLoadable instances.
     * @param bool $matching Whether it is an association loaded through `matching()`.
     * @return array
     */
    protected auto _buildAssociationsMap(array $map, array $level, bool $matching = false): array
    {
        foreach ($level as $assoc => $meta) {
            $canBeJoined = $meta.canBeJoined();
            $instance = $meta.instance();
            $associations = $meta.associations();
            $forMatching = $meta.forMatching();
            $map[] = [
                'alias' => $assoc,
                'instance' => $instance,
                'canBeJoined' => $canBeJoined,
                'entityClass' => $instance.getTarget().getEntityClass(),
                'nestKey' => $canBeJoined ? $assoc : $meta.aliasPath(),
                'matching' => $forMatching ?? $matching,
                'targetProperty' => $meta.targetProperty(),
            ];
            if ($canBeJoined && $associations) {
                $map = this._buildAssociationsMap($map, $associations, $matching);
            }
        }

        return $map;
    }

    /**
     * Registers a table alias, typically loaded as a join in a query, as belonging to
     * an association. This helps hydrators know what to do with the columns coming
     * from such joined table.
     *
     * @param string myAlias The table alias as it appears in the query.
     * @param \Cake\ORM\Association $assoc The association object the alias represents;
     * will be normalized
     * @param bool $asMatching Whether this join results should be treated as a
     * 'matching' association.
     * @param string|null myTargetProperty The property name where the results of the join should be nested at.
     * If not passed, the default property for the association will be used.
     * @return void
     */
    function addToJoinsMap(
        string myAlias,
        Association $assoc,
        bool $asMatching = false,
        Nullable!string myTargetProperty = null
    ): void {
        this._joinsMap[myAlias] = new EagerLoadable(myAlias, [
            'aliasPath' => myAlias,
            'instance' => $assoc,
            'canBeJoined' => true,
            'forMatching' => $asMatching,
            'targetProperty' => myTargetProperty ?: $assoc.getProperty(),
        ]);
    }

    /**
     * Helper function used to return the keys from the query records that will be used
     * to eagerly load associations.
     *
     * @param array<\Cake\ORM\EagerLoadable> $external the list of external associations to be loaded
     * @param \Cake\ORM\Query myQuery The query from which the results where generated
     * @param \Cake\Database\IStatement $statement The statement to work on
     * @return array
     */
    protected auto _collectKeys(array $external, Query myQuery, $statement): array
    {
        $collectKeys = [];
        foreach ($external as $meta) {
            $instance = $meta.instance();
            if (!$instance.requiresKeys($meta.getConfig())) {
                continue;
            }

            $source = $instance.getSource();
            myKeys = $instance.type() === Association::MANY_TO_ONE ?
                (array)$instance.getForeignKey() :
                (array)$instance.getBindingKey();

            myAlias = $source.getAlias();
            $pkFields = [];
            foreach (myKeys as myKey) {
                $pkFields[] = key(myQuery.aliasField(myKey, myAlias));
            }
            $collectKeys[$meta.aliasPath()] = [myAlias, $pkFields, count($pkFields) === 1];
        }
        if (empty($collectKeys)) {
            return [[], $statement];
        }

        if (!($statement instanceof BufferedStatement)) {
            $statement = new BufferedStatement($statement, myQuery.getConnection().getDriver());
        }

        return [this._groupKeys($statement, $collectKeys), $statement];
    }

    /**
     * Helper function used to iterate a statement and extract the columns
     * defined in $collectKeys
     *
     * @param \Cake\Database\Statement\BufferedStatement $statement The statement to read from.
     * @param array<string, array> $collectKeys The keys to collect
     * @return array
     */
    protected auto _groupKeys(BufferedStatement $statement, array $collectKeys): array
    {
        myKeys = [];
        foreach (($statement.fetchAll('assoc') ?: []) as myResult) {
            foreach ($collectKeys as $nestKey => $parts) {
                if ($parts[2] === true) {
                    // Missed joins will have null in the results.
                    if (!array_key_exists($parts[1][0], myResult)) {
                        continue;
                    }
                    // Assign empty array to avoid not found association when optional.
                    if (!isset(myResult[$parts[1][0]])) {
                        if (!isset(myKeys[$nestKey][$parts[0]])) {
                            myKeys[$nestKey][$parts[0]] = [];
                        }
                    } else {
                        myValue = myResult[$parts[1][0]];
                        myKeys[$nestKey][$parts[0]][myValue] = myValue;
                    }
                    continue;
                }

                // Handle composite keys.
                $collected = [];
                foreach ($parts[1] as myKey) {
                    $collected[] = myResult[myKey];
                }
                myKeys[$nestKey][$parts[0]][implode(';', $collected)] = $collected;
            }
        }
        $statement.rewind();

        return myKeys;
    }

    /**
     * Handles cloning eager loaders and eager loadables.
     *
     * @return void
     */
    auto __clone() {
        if (this._matching) {
            this._matching = clone this._matching;
        }
    }
}