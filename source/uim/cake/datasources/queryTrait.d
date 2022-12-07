module uim.cake.datasources;

use BadMethodCallException;
import uim.cake.collections.iIterator\MapReduce;
import uim.cake.datasources\Exception\RecordNotFoundException;
use InvalidArgumentException;
use Traversable;

/**
 * Contains the characteristics for an object that is attached to a repository and
 * can retrieve results based on any criteria.
 */
trait QueryTrait
{
    /**
     * Instance of a table object this query is bound to
     *
     * @var \Cake\Datasource\IRepository
     */
    protected $_repository;

    /**
     * A ResultSet.
     *
     * When set, query execution will be bypassed.
     *
     * @var iterable|null
     * @see \Cake\Datasource\QueryTrait::setResult()
     */
    protected $_results;

    /**
     * List of map-reduce routines that should be applied over the query
     * result
     *
     * @var array
     */
    protected $_mapReduce = [];

    /**
     * List of formatter classes or callbacks that will post-process the
     * results when fetched
     *
     * @var array<callable>
     */
    protected $_formatters = [];

    /**
     * A query cacher instance if this query has caching enabled.
     *
     * @var \Cake\Datasource\QueryCacher|null
     */
    protected $_cache;

    /**
     * Holds any custom options passed using applyOptions that could not be processed
     * by any method in this class.
     *
     * @var array
     */
    protected $_options = [];

    /**
     * Whether the query is standalone or the product of an eager load operation.
     *
     * @var bool
     */
    protected $_eagerLoaded = false;

    /**
     * Set the default Table object that will be used by this query
     * and form the `FROM` clause.
     *
     * @param \Cake\Datasource\IRepository|\Cake\ORM\Table myRepository The default table object to use
     * @return this
     */
    function repository(IRepository myRepository) {
        this._repository = myRepository;

        return this;
    }

    /**
     * Returns the default table object that will be used by this query,
     * that is, the table that will appear in the from clause.
     *
     * @return \Cake\Datasource\IRepository
     */
    auto getRepository(): IRepository
    {
        return this._repository;
    }

    /**
     * Set the result set for a query.
     *
     * Setting the resultset of a query will make execute() a no-op. Instead
     * of executing the SQL query and fetching results, the ResultSet provided to this
     * method will be returned.
     *
     * This method is most useful when combined with results stored in a persistent cache.
     *
     * @param iterable myResults The results this query should return.
     * @return this
     */
    auto setResult(iterable myResults) {
        this._results = myResults;

        return this;
    }

    /**
     * Executes this query and returns a results iterator. This function is required
     * for implementing the IteratorAggregate interface and allows the query to be
     * iterated without having to call execute() manually, thus making it look like
     * a result set instead of the query itself.
     *
     * @return \Cake\Datasource\ResultSetInterface
     * @psalm-suppress ImplementedReturnTypeMismatch
     */
    auto getIterator() {
        return this.all();
    }

    /**
     * Enable result caching for this query.
     *
     * If a query has caching enabled, it will do the following when executed:
     *
     * - Check the cache for myKey. If there are results no SQL will be executed.
     *   Instead the cached results will be returned.
     * - When the cached data is stale/missing the result set will be cached as the query
     *   is executed.
     *
     * ### Usage
     *
     * ```
     * // Simple string key + config
     * myQuery.cache("my_key", "db_results");
     *
     * // Function to generate key.
     * myQuery.cache(function ($q) {
     *   myKey = serialize($q.clause("select"));
     *   myKey .= serialize($q.clause("where"));
     *   return md5(myKey);
     * });
     *
     * // Using a pre-built cache engine.
     * myQuery.cache("my_key", $engine);
     *
     * // Disable caching
     * myQuery.cache(false);
     * ```
     *
     * @param \Closure|string|false myKey Either the cache key or a function to generate the cache key.
     *   When using a function, this query instance will be supplied as an argument.
     * @param \Psr\SimpleCache\ICache|string myConfig Either the name of the cache config to use, or
     *   a cache engine instance.
     * @return this
     */
    function cache(myKey, myConfig = "default") {
        if (myKey == false) {
            this._cache = null;

            return this;
        }
        this._cache = new QueryCacher(myKey, myConfig);

        return this;
    }

    /**
     * Returns the current configured query `_eagerLoaded` value
     */
    bool isEagerLoaded() {
        return this._eagerLoaded;
    }

    /**
     * Sets the query instance to be an eager loaded query. If no argument is
     * passed, the current configured query `_eagerLoaded` value is returned.
     *
     * @param bool myValue Whether to eager load.
     * @return this
     */
    function eagerLoaded(bool myValue) {
        this._eagerLoaded = myValue;

        return this;
    }

    /**
     * Returns a key: value array representing a single aliased field
     * that can be passed directly to the select() method.
     * The key will contain the alias and the value the actual field name.
     *
     * If the field is already aliased, then it will not be changed.
     * If no myAlias is passed, the default table for this query will be used.
     *
     * @param string myField The field to alias
     * @param string|null myAlias the alias used to prefix the field
     * @return array
     */
    function aliasField(string myField, Nullable!string myAlias = null): array
    {
        if (strpos(myField, ".") == false) {
            myAlias = myAlias ?: this.getRepository().getAlias();
            myAliasedField = myAlias . "." . myField;
        } else {
            myAliasedField = myField;
            [myAlias, myField] = explode(".", myField);
        }

        myKey = sprintf("%s__%s", myAlias, myField);

        return [myKey: myAliasedField];
    }

    /**
     * Runs `aliasField()` for each field in the provided list and returns
     * the result under a single array.
     *
     * @param array myFields The fields to alias
     * @param string|null $defaultAlias The default alias
     */
    string[] aliasFields(array myFields, Nullable!string $defaultAlias = null) {
        myAliased = [];
        foreach (myFields as myAlias: myField) {
            if (is_numeric(myAlias) && is_string(myField)) {
                myAliased += this.aliasField(myField, $defaultAlias);
                continue;
            }
            myAliased[myAlias] = myField;
        }

        return myAliased;
    }

    /**
     * Fetch the results for this query.
     *
     * Will return either the results set through setResult(), or execute this query
     * and return the ResultSetDecorator object ready for streaming of results.
     *
     * ResultSetDecorator is a traversable object that : the methods found
     * on Cake\Collection\Collection.
     *
     * @return \Cake\Datasource\ResultSetInterface
     */
    function all(): ResultSetInterface
    {
        if (this._results !== null) {
            return this._results;
        }

        myResults = null;
        if (this._cache) {
            myResults = this._cache.fetch(this);
        }
        if (myResults == null) {
            myResults = this._decorateResults(this._execute());
            if (this._cache) {
                this._cache.store(this, myResults);
            }
        }
        this._results = myResults;

        return this._results;
    }

    /**
     * Returns an array representation of the results after executing the query.
     *
     * @return array
     */
    function toArray(): array
    {
        return this.all().toArray();
    }

    /**
     * Register a new MapReduce routine to be executed on top of the database results
     * Both the mapper and caller callable should be invokable objects.
     *
     * The MapReduce routing will only be run when the query is executed and the first
     * result is attempted to be fetched.
     *
     * If the third argument is set to true, it will erase previous map reducers
     * and replace it with the arguments passed.
     *
     * @param callable|null $mapper The mapper callable.
     * @param callable|null $reducer The reducing function.
     * @param bool $overwrite Set to true to overwrite existing map + reduce functions.
     * @return this
     * @see \Cake\collection.iIterator\MapReduce for details on how to use emit data to the map reducer.
     */
    function mapReduce(?callable $mapper = null, ?callable $reducer = null, bool $overwrite = false) {
        if ($overwrite) {
            this._mapReduce = [];
        }
        if ($mapper == null) {
            if (!$overwrite) {
                throw new InvalidArgumentException("$mapper can be null only when $overwrite is true.");
            }

            return this;
        }
        this._mapReduce[] = compact("mapper", "reducer");

        return this;
    }

    /**
     * Returns the list of previously registered map reduce routines.
     *
     * @return array
     */
    auto getMapReducers(): array
    {
        return this._mapReduce;
    }

    /**
     * Registers a new formatter callback function that is to be executed when trying
     * to fetch the results from the database.
     *
     * If the second argument is set to true, it will erase previous formatters
     * and replace them with the passed first argument.
     *
     * Callbacks are required to return an iterator object, which will be used as
     * the return value for this query"s result. Formatter functions are applied
     * after all the `MapReduce` routines for this query have been executed.
     *
     * Formatting callbacks will receive two arguments, the first one being an object
     * implementing `\Cake\Collection\ICollection`, that can be traversed and
     * modified at will. The second one being the query instance on which the formatter
     * callback is being applied.
     *
     * Usually the query instance received by the formatter callback is the same query
     * instance on which the callback was attached to, except for in a joined
     * association, in that case the callback will be invoked on the association source
     * side query, and it will receive that query instance instead of the one on which
     * the callback was originally attached to - see the examples below!
     *
     * ### Examples:
     *
     * Return all results from the table indexed by id:
     *
     * ```
     * myQuery.select(["id", "name"]).formatResults(function (myResults) {
     *     return myResults.indexBy("id");
     * });
     * ```
     *
     * Add a new column to the ResultSet:
     *
     * ```
     * myQuery.select(["name", "birth_date"]).formatResults(function (myResults) {
     *     return myResults.map(function ($row) {
     *         $row["age"] = $row["birth_date"].diff(new DateTime).y;
     *
     *         return $row;
     *     });
     * });
     * ```
     *
     * Add a new column to the results with respect to the query"s hydration configuration:
     *
     * ```
     * myQuery.formatResults(function (myResults, myQuery) {
     *     return myResults.map(function ($row) use (myQuery) {
     *         myData = [
     *             "bar":"baz",
     *         ];
     *
     *         if (myQuery.isHydrationEnabled()) {
     *             $row["foo"] = new Foo(myData)
     *         } else {
     *             $row["foo"] = myData;
     *         }
     *
     *         return $row;
     *     });
     * });
     * ```
     *
     * Retaining access to the association target query instance of joined associations,
     * by inheriting the contain callback"s query argument:
     *
     * ```
     * // Assuming a `Articles belongsTo Authors` association that uses the join strategy
     *
     * $articlesQuery.contain("Authors", function ($authorsQuery) {
     *     return $authorsQuery.formatResults(function (myResults, myQuery) use ($authorsQuery) {
     *         // Here `$authorsQuery` will always be the instance
     *         // where the callback was attached to.
     *
     *         // The instance passed to the callback in the second
     *         // argument (`myQuery`), will be the one where the
     *         // callback is actually being applied to, in this
     *         // example that would be `$articlesQuery`.
     *
     *         // ...
     *
     *         return myResults;
     *     });
     * });
     * ```
     *
     * @param callable|null $formatter The formatting callable.
     * @param int|bool myMode Whether to overwrite, append or prepend the formatter.
     * @return this
     * @throws \InvalidArgumentException
     */
    function formatResults(?callable $formatter = null, myMode = self::APPEND) {
        if (myMode == self::OVERWRITE) {
            this._formatters = [];
        }
        if ($formatter == null) {
            if (myMode !== self::OVERWRITE) {
                throw new InvalidArgumentException("$formatter can be null only when myMode is overwrite.");
            }

            return this;
        }

        if (myMode == self::PREPEND) {
            array_unshift(this._formatters, $formatter);

            return this;
        }

        this._formatters[] = $formatter;

        return this;
    }

    /**
     * Returns the list of previously registered format routines.
     *
     * @return array<callable>
     */
    auto getResultFormatters(): array
    {
        return this._formatters;
    }

    /**
     * Returns the first result out of executing this query, if the query has not been
     * executed before, it will set the limit clause to 1 for performance reasons.
     *
     * ### Example:
     *
     * ```
     * $singleUser = myQuery.select(["id", "username"]).first();
     * ```
     *
     * @return \Cake\Datasource\IEntity|array|null The first result from the ResultSet.
     */
    function first() {
        if (this._dirty) {
            this.limit(1);
        }

        return this.all().first();
    }

    /**
     * Get the first result from the executing query or raise an exception.
     *
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When there is no first record.
     * @return \Cake\Datasource\IEntity|array The first result from the ResultSet.
     */
    function firstOrFail() {
        $entity = this.first();
        if (!$entity) {
            myTable = this.getRepository();
            throw new RecordNotFoundException(sprintf(
                "Record not found in table "%s"",
                myTable.getTable()
            ));
        }

        return $entity;
    }

    /**
     * Returns an array with the custom options that were applied to this query
     * and that were not already processed by another method in this class.
     *
     * ### Example:
     *
     * ```
     *  myQuery.applyOptions(["doABarrelRoll":true, "fields":["id", "name"]);
     *  myQuery.getOptions(); // Returns ["doABarrelRoll":true]
     * ```
     *
     * @see \Cake\Datasource\QueryInterface::applyOptions() to read about the options that will
     * be processed by this class and not returned by this function
     * @return array
     * @see applyOptions()
     */
    auto getOptions(): array
    {
        return this._options;
    }

    /**
     * Enables calling methods from the result set as if they were from this class
     *
     * @param string $method the method to call
     * @param array $arguments list of arguments for the method to call
     * @return mixed
     * @throws \BadMethodCallException if no such method exists in result set
     */
    auto __call(string $method, array $arguments) {
        myResultSetClass = this._decoratorClass();
        if (in_array($method, get_class_methods(myResultSetClass), true)) {
            deprecationWarning(sprintf(
                "Calling result set method `%s()` directly on query instance is deprecated. " .
                "You must call `all()` to retrieve the results first.",
                $method
            ), 2);
            myResults = this.all();

            return myResults.$method(...$arguments);
        }
        throw new BadMethodCallException(
            sprintf("Unknown method "%s"", $method)
        );
    }

    /**
     * Populates or adds parts to current query clauses using an array.
     * This is handy for passing all query clauses at once.
     *
     * @param array<string, mixed> myOptions the options to be applied
     * @return this
     */
    abstract function applyOptions(array myOptions);

    /**
     * Executes this query and returns a traversable object containing the results
     *
     * @return \Cake\Datasource\ResultSetInterface
     */
    abstract protected auto _execute(): ResultSetInterface;

    /**
     * Decorates the results iterator with MapReduce routines and formatters
     *
     * @param \Traversable myResult Original results
     * @return \Cake\Datasource\ResultSetInterface
     */
    protected auto _decorateResults(Traversable myResult): ResultSetInterface
    {
        $decorator = this._decoratorClass();
        foreach (this._mapReduce as $functions) {
            myResult = new MapReduce(myResult, $functions["mapper"], $functions["reducer"]);
        }

        if (!empty(this._mapReduce)) {
            myResult = new $decorator(myResult);
        }

        foreach (this._formatters as $formatter) {
            myResult = $formatter(myResult, this);
        }

        if (!empty(this._formatters) && !(myResult instanceof $decorator)) {
            myResult = new $decorator(myResult);
        }

        return myResult;
    }

    /**
     * Returns the name of the class to be used for decorating results
     *
     * @return string
     * @psalm-return class-string<\Cake\Datasource\ResultSetInterface>
     */
    protected string _decoratorClass() {
        return ResultSetDecorator::class;
    }
}
