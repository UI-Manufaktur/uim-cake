module uim.cake.ORM;

import uim.cake.collection\Collection;
import uim.cake.collection\CollectionTrait;
import uim.cake.database.Exception\DatabaseException;
import uim.cake.database.IStatement;
import uim.cake.Datasource\IEntity;
import uim.cake.Datasource\ResultSetInterface;
use SplFixedArray;

/**
 * Represents the results obtained after executing a query for a specific table
 * This object is responsible for correctly nesting result keys reported from
 * the query, casting each field to the correct type and executing the extra
 * queries required for eager loading external associations.
 */
class ResultSet : ResultSetInterface
{
    use CollectionTrait;

    /**
     * Database statement holding the results
     *
     * @var \Cake\Database\IStatement
     */
    protected $_statement;

    /**
     * Points to the next record number that should be fetched
     *
     * @var int
     */
    protected $_index = 0;

    /**
     * Last record fetched from the statement
     *
     * @var object|array
     */
    protected $_current;

    /**
     * Default table instance
     *
     * @var \Cake\ORM\Table
     */
    protected $_defaultTable;

    /**
     * The default table alias
     *
     * @var string
     */
    protected $_defaultAlias;

    /**
     * List of associations that should be placed under the `_matchingData`
     * result key.
     *
     * @var array
     */
    protected $_matchingMap = [];

    /**
     * List of associations that should be eager loaded.
     *
     * @var array
     */
    protected $_containMap = [];

    /**
     * Map of fields that are fetched from the statement with
     * their type and the table they belong to
     *
     * @var array
     */
    protected $_map = [];

    /**
     * List of matching associations and the column keys to expect
     * from each of them.
     *
     * @var array
     */
    protected $_matchingMapColumns = [];

    /**
     * Results that have been fetched or hydrated into the results.
     *
     * @var \SplFixedArray|array
     */
    protected $_results = [];

    /**
     * Whether to hydrate results into objects or not
     *
     * @var bool
     */
    protected $_hydrate = true;

    /**
     * Tracks value of $_autoFields property of myQuery passed to constructor.
     *
     * @var bool|null
     */
    protected $_autoFields;

    /**
     * The fully moduled name of the class to use for hydrating results
     *
     * @var string
     */
    protected $_entityClass;

    /**
     * Whether to buffer results fetched from the statement
     *
     * @var bool
     */
    protected $_useBuffering = true;

    /**
     * Holds the count of records in this result set
     *
     * @var int
     */
    protected $_count;

    /**
     * The Database driver object.
     *
     * Cached in a property to avoid multiple calls to the same function.
     *
     * @var \Cake\Database\IDriver
     */
    protected $_driver;

    /**
     * Constructor
     *
     * @param \Cake\ORM\Query myQuery Query from where results come
     * @param \Cake\Database\IStatement $statement The statement to fetch from
     */
    this(Query myQuery, IStatement $statement)
    {
        myRepository = myQuery.getRepository();
        this._statement = $statement;
        this._driver = myQuery.getConnection().getDriver();
        this._defaultTable = myRepository;
        this._calculateAssociationMap(myQuery);
        this._hydrate = myQuery.isHydrationEnabled();
        this._entityClass = myRepository.getEntityClass();
        this._useBuffering = myQuery.isBufferedResultsEnabled();
        this._defaultAlias = this._defaultTable.getAlias();
        this._calculateColumnMap(myQuery);
        this._autoFields = myQuery.isAutoFieldsEnabled();

        if (this._useBuffering) {
            myCount = this.count();
            this._results = new SplFixedArray(myCount);
        }
    }

    /**
     * Returns the current record in the result iterator
     *
     * Part of Iterator interface.
     *
     * @return object|array
     */
    #[\ReturnTypeWillChange]
    function current() {
        return this._current;
    }

    /**
     * Returns the key of the current record in the iterator
     *
     * Part of Iterator interface.
     *
     * @return int
     */
    function key(): int
    {
        return this._index;
    }

    /**
     * Advances the iterator pointer to the next record
     *
     * Part of Iterator interface.
     *
     * @return void
     */
    function next(): void
    {
        this._index++;
    }

    /**
     * Rewinds a ResultSet.
     *
     * Part of Iterator interface.
     *
     * @throws \Cake\Database\Exception\DatabaseException
     * @return void
     */
    function rewind(): void
    {
        if (this._index === 0) {
            return;
        }

        if (!this._useBuffering) {
            $msg = 'You cannot rewind an un-buffered ResultSet. '
                . 'Use Query::bufferResults() to get a buffered ResultSet.';
            throw new DatabaseException($msg);
        }

        this._index = 0;
    }

    /**
     * Whether there are more results to be fetched from the iterator
     *
     * Part of Iterator interface.
     *
     * @return bool
     */
    function valid(): bool
    {
        if (this._useBuffering) {
            $valid = this._index < this._count;
            if ($valid && this._results[this._index] !== null) {
                this._current = this._results[this._index];

                return true;
            }
            if (!$valid) {
                return $valid;
            }
        }

        this._current = this._fetchResult();
        $valid = this._current !== false;

        if ($valid && this._useBuffering) {
            this._results[this._index] = this._current;
        }
        if (!$valid && this._statement !== null) {
            this._statement.closeCursor();
        }

        return $valid;
    }

    /**
     * Get the first record from a result set.
     *
     * This method will also close the underlying statement cursor.
     *
     * @return object|array|null
     */
    function first() {
        foreach (this as myResult) {
            if (this._statement !== null && !this._useBuffering) {
                this._statement.closeCursor();
            }

            return myResult;
        }

        return null;
    }

    /**
     * Serializes a resultset.
     *
     * Part of Serializable interface.
     *
     * @return string Serialized object
     */
    function serialize(): string
    {
        return serialize(this.__serialize());
    }

    /**
     * Serializes a resultset.
     *
     * @return array
     */
    auto __serialize(): array
    {
        if (!this._useBuffering) {
            $msg = 'You cannot serialize an un-buffered ResultSet. '
                . 'Use Query::bufferResults() to get a buffered ResultSet.';
            throw new DatabaseException($msg);
        }

        while (this.valid()) {
            this.next();
        }

        if (this._results instanceof SplFixedArray) {
            return this._results.toArray();
        }

        return this._results;
    }

    /**
     * Unserializes a resultset.
     *
     * Part of Serializable interface.
     *
     * @param string $serialized Serialized object
     * @return void
     */
    function unserialize($serialized)
    {
        this.__unserialize((array)(unserialize($serialized) ?: []));
    }

    /**
     * Unserializes a resultset.
     *
     * @param array myData Data array.
     * @return void
     */
    auto __unserialize(array myData): void
    {
        this._results = SplFixedArray::fromArray(myData);
        this._useBuffering = true;
        this._count = this._results.count();
    }

    /**
     * Gives the number of rows in the result set.
     *
     * Part of the Countable interface.
     *
     * @return int
     */
    function count(): int
    {
        if (this._count !== null) {
            return this._count;
        }
        if (this._statement !== null) {
            return this._count = this._statement.rowCount();
        }

        if (this._results instanceof SplFixedArray) {
            this._count = this._results.count();
        } else {
            this._count = count(this._results);
        }

        return this._count;
    }

    /**
     * Calculates the list of associations that should get eager loaded
     * when fetching each record
     *
     * @param \Cake\ORM\Query myQuery The query from where to derive the associations
     * @return void
     */
    protected auto _calculateAssociationMap(Query myQuery): void
    {
        $map = myQuery.getEagerLoader().associationsMap(this._defaultTable);
        this._matchingMap = (new Collection($map))
            .match(['matching' => true])
            .indexBy('alias')
            .toArray();

        this._containMap = (new Collection(array_reverse($map)))
            .match(['matching' => false])
            .indexBy('nestKey')
            .toArray();
    }

    /**
     * Creates a map of row keys out of the query select clause that can be
     * used to hydrate nested result sets more quickly.
     *
     * @param \Cake\ORM\Query myQuery The query from where to derive the column map
     * @return void
     */
    protected auto _calculateColumnMap(Query myQuery): void
    {
        $map = [];
        foreach (myQuery.clause('select') as myKey => myField) {
            myKey = trim(myKey, '"`[]');

            if (strpos(myKey, '__') <= 0) {
                $map[this._defaultAlias][myKey] = myKey;
                continue;
            }

            $parts = explode('__', myKey, 2);
            $map[$parts[0]][myKey] = $parts[1];
        }

        foreach (this._matchingMap as myAlias => $assoc) {
            if (!isset($map[myAlias])) {
                continue;
            }
            this._matchingMapColumns[myAlias] = $map[myAlias];
            unset($map[myAlias]);
        }

        this._map = $map;
    }

    /**
     * Helper function to fetch the next result from the statement or
     * seeded results.
     *
     * @return mixed
     */
    protected auto _fetchResult() {
        if (this._statement === null) {
            return false;
        }

        $row = this._statement.fetch('assoc');
        if ($row === false) {
            return $row;
        }

        return this._groupResult($row);
    }

    /**
     * Correctly nests results keys including those coming from associations
     *
     * @param array $row Array containing columns and values or false if there is no results
     * @return \Cake\Datasource\IEntity|array Results
     */
    protected auto _groupResult(array $row)
    {
        $defaultAlias = this._defaultAlias;
        myResults = $presentAliases = [];
        myOptions = [
            'useSetters' => false,
            'markClean' => true,
            'markNew' => false,
            'guard' => false,
        ];

        foreach (this._matchingMapColumns as myAlias => myKeys) {
            $matching = this._matchingMap[myAlias];
            myResults['_matchingData'][myAlias] = array_combine(
                myKeys,
                array_intersect_key($row, myKeys)
            );
            if (this._hydrate) {
                /** @var \Cake\ORM\Table myTable */
                myTable = $matching['instance'];
                myOptions['source'] = myTable.getRegistryAlias();
                /** @var \Cake\Datasource\IEntity $entity */
                $entity = new $matching['entityClass'](myResults['_matchingData'][myAlias], myOptions);
                myResults['_matchingData'][myAlias] = $entity;
            }
        }

        foreach (this._map as myTable => myKeys) {
            myResults[myTable] = array_combine(myKeys, array_intersect_key($row, myKeys));
            $presentAliases[myTable] = true;
        }

        // If the default table is not in the results, set
        // it to an empty array so that any contained
        // associations hydrate correctly.
        myResults[$defaultAlias] = myResults[$defaultAlias] ?? [];

        unset($presentAliases[$defaultAlias]);

        foreach (this._containMap as $assoc) {
            myAlias = $assoc['nestKey'];

            if ($assoc['canBeJoined'] && empty(this._map[myAlias])) {
                continue;
            }

            /** @var \Cake\ORM\Association $instance */
            $instance = $assoc['instance'];

            if (!$assoc['canBeJoined'] && !isset($row[myAlias])) {
                myResults = $instance.defaultRowValue(myResults, $assoc['canBeJoined']);
                continue;
            }

            if (!$assoc['canBeJoined']) {
                myResults[myAlias] = $row[myAlias];
            }

            myTarget = $instance.getTarget();
            myOptions['source'] = myTarget.getRegistryAlias();
            unset($presentAliases[myAlias]);

            if ($assoc['canBeJoined'] && this._autoFields !== false) {
                $hasData = false;
                foreach (myResults[myAlias] as $v) {
                    if ($v !== null && $v !== []) {
                        $hasData = true;
                        break;
                    }
                }

                if (!$hasData) {
                    myResults[myAlias] = null;
                }
            }

            if (this._hydrate && myResults[myAlias] !== null && $assoc['canBeJoined']) {
                $entity = new $assoc['entityClass'](myResults[myAlias], myOptions);
                myResults[myAlias] = $entity;
            }

            myResults = $instance.transformRow(myResults, myAlias, $assoc['canBeJoined'], $assoc['targetProperty']);
        }

        foreach ($presentAliases as myAlias => $present) {
            if (!isset(myResults[myAlias])) {
                continue;
            }
            myResults[$defaultAlias][myAlias] = myResults[myAlias];
        }

        if (isset(myResults['_matchingData'])) {
            myResults[$defaultAlias]['_matchingData'] = myResults['_matchingData'];
        }

        myOptions['source'] = this._defaultTable.getRegistryAlias();
        if (isset(myResults[$defaultAlias])) {
            myResults = myResults[$defaultAlias];
        }
        if (this._hydrate && !(myResults instanceof IEntity)) {
            myResults = new this._entityClass(myResults, myOptions);
        }

        return myResults;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array
     */
    auto __debugInfo() {
        return [
            'items' => this.toArray(),
        ];
    }
}
