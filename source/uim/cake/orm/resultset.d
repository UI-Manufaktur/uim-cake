/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.orm;

@safe:
import uim.cake;

/**
 * Represents the results obtained after executing a query for a specific table
 * This object is responsible for correctly nesting result keys reported from
 * the query, casting each field to the correct type and executing the extra
 * queries required for eager loading external associations.
 */
class ResultSet : IResultSet
{
    use CollectionTrait;

    /**
     * Database statement holding the results
     *
     * @var uim.cake.databases.IStatement
     */
    protected _statement;

    // Points to the next record number that should be fetched
    protected int $_index = 0;

    /**
     * Last record fetched from the statement
     *
     * @var object|array
     */
    protected _current;

    /**
     * Default table instance
     *
     * @var uim.cake.orm.Table
     */
    protected _defaultTable;

    /**
     * The default table alias
     */
    protected string _defaultAlias;

    /**
     * List of associations that should be placed under the `_matchingData`
     * result key.
     *
     * @var array
     */
    protected _matchingMap = [];

    /**
     * List of associations that should be eager loaded.
     *
     * @var array
     */
    protected _containMap = [];

    /**
     * Map of fields that are fetched from the statement with
     * their type and the table they belong to
     *
     * @var array
     */
    protected _map = [];

    /**
     * List of matching associations and the column keys to expect
     * from each of them.
     *
     * @var array
     */
    protected _matchingMapColumns = [];

    /**
     * Results that have been fetched or hydrated into the results.
     *
     * @var \SplFixedArray|array
     */
    protected _results = [];

    /**
     * Whether to hydrate results into objects or not
     *
     * @var bool
     */
    protected _hydrate = true;

    /**
     * Tracks value of $_autoFields property of myQuery passed to constructor.
     *
     * @var bool|null
     */
    protected _autoFields;

    /**
     * The fully moduled name of the class to use for hydrating results
     */
    protected string _entityClass;

    /**
     * Whether to buffer results fetched from the statement
     *
     * @var bool
     */
    protected _useBuffering = true;

    /**
     * Holds the count of records in this result set
     *
     * @var int
     */
    protected _count;

    /**
     * The Database driver object.
     *
     * Cached in a property to avoid multiple calls to the same function.
     *
     * @var uim.cake.databases.IDriver
     */
    protected _driver;

    /**
     * Constructor
     *
     * @param uim.cake.orm.Query myQuery Query from where results come
     * @param uim.cake.databases.IStatement $statement The statement to fetch from
     */
    this(Query myQuery, IStatement $statement) {
        myRepository = myQuery.getRepository();
        _statement = $statement;
        _driver = myQuery.getConnection().getDriver();
        _defaultTable = myRepository;
        _calculateAssociationMap(myQuery);
        _hydrate = myQuery.isHydrationEnabled();
        _entityClass = myRepository.getEntityClass();
        _useBuffering = myQuery.isBufferedResultsEnabled();
        _defaultAlias = _defaultTable.getAlias();
        _calculateColumnMap(myQuery);
        _autoFields = myQuery.isAutoFieldsEnabled();

        if (_useBuffering) {
            myCount = this.count();
            _results = new SplFixedArray(myCount);
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
        return _current;
    }

    /**
     * Returns the key of the current record in the iterator
     *
     * Part of Iterator interface.
     */
    int key() {
        return _index;
    }

    /**
     * Advances the iterator pointer to the next record
     *
     * Part of Iterator interface.
     */
    void next() {
        _index++;
    }

    /**
     * Rewinds a ResultSet.
     *
     * Part of Iterator interface.
     *
     * @throws uim.cake.databases.exceptions.DatabaseException
     */
    void rewind() {
        if (_index == 0) {
            return;
        }

        if (!_useBuffering) {
            $msg = "You cannot rewind an un-buffered ResultSet. "
                . "Use Query::bufferResults() to get a buffered ResultSet.";
            throw new DatabaseException($msg);
        }

        _index = 0;
    }

    /**
     * Whether there are more results to be fetched from the iterator
     *
     * Part of Iterator interface.
     */
    bool valid() {
        if (_useBuffering) {
            $valid = _index < _count;
            if ($valid && _results[_index]  !is null) {
                _current = _results[_index];

                return true;
            }
            if (!$valid) {
                return $valid;
            }
        }

        _current = _fetchResult();
        $valid = _current != false;

        if ($valid && _useBuffering) {
            _results[_index] = _current;
        }
        if (!$valid && _statement  !is null) {
            _statement.closeCursor();
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
            if (_statement  !is null && !_useBuffering) {
                _statement.closeCursor();
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
    string serialize() {
        return serialize(__serialize());
    }

    /**
     * Serializes a resultset.
     *
     * @return array
     */
    auto __serialize(): array
    {
        if (!_useBuffering) {
            $msg = "You cannot serialize an un-buffered ResultSet. "
                . "Use Query::bufferResults() to get a buffered ResultSet.";
            throw new DatabaseException($msg);
        }

        while (this.valid()) {
            this.next();
        }

        if (_results instanceof SplFixedArray) {
            return _results.toArray();
        }

        return _results;
    }

    /**
     * Unserializes a resultset.
     *
     * Part of Serializable interface.
     *
     * @param string serialized Serialized object
     */
    void unserialize($serialized) {
        __unserialize((array)(unserialize($serialized) ?: []));
    }

    /**
     * Unserializes a resultset.
     *
     * @param array myData Data array.
     */
    void __unserialize(array myData) {
        _results = SplFixedArray::fromArray(myData);
        _useBuffering = true;
        _count = _results.count();
    }

    /**
     * Gives the number of rows in the result set.
     *
     * Part of the Countable interface.
     */
    int count() {
        if (_count  !is null) {
            return _count;
        }
        if (_statement  !is null) {
            return _count = _statement.rowCount();
        }

        if (_results instanceof SplFixedArray) {
            _count = _results.count();
        } else {
            _count = count(_results);
        }

        return _count;
    }

    /**
     * Calculates the list of associations that should get eager loaded
     * when fetching each record
     *
     * @param uim.cake.orm.Query myQuery The query from where to derive the associations
     */
    protected void _calculateAssociationMap(Query myQuery) {
        $map = myQuery.getEagerLoader().associationsMap(_defaultTable);
        _matchingMap = (new Collection($map))
            .match(["matching":true])
            .indexBy("alias")
            .toArray();

        _containMap = (new Collection(array_reverse($map)))
            .match(["matching":false])
            .indexBy("nestKey")
            .toArray();
    }

    /**
     * Creates a map of row keys out of the query select clause that can be
     * used to hydrate nested result sets more quickly.
     *
     * @param uim.cake.orm.Query myQuery The query from where to derive the column map
     */
    protected void _calculateColumnMap(Query myQuery) {
        $map = [];
        foreach (myQuery.clause("select") as myKey: myField) {
            myKey = trim(myKey, ""`[]");

            if (indexOf(myKey, "__") <= 0) {
                $map[_defaultAlias][myKey] = myKey;
                continue;
            }

            $parts = explode("__", myKey, 2);
            $map[$parts[0]][myKey] = $parts[1];
        }

        foreach (_matchingMap as myAlias: $assoc) {
            if (!isset($map[myAlias])) {
                continue;
            }
            _matchingMapColumns[myAlias] = $map[myAlias];
            unset($map[myAlias]);
        }

        _map = $map;
    }

    /**
     * Helper function to fetch the next result from the statement or
     * seeded results.
     *
     * @return mixed
     */
    protected auto _fetchResult() {
        if (_statement is null) {
            return false;
        }

        $row = _statement.fetch("assoc");
        if ($row == false) {
            return $row;
        }

        return _groupResult($row);
    }

    /**
     * Correctly nests results keys including those coming from associations
     *
     * @param array $row Array containing columns and values or false if there is no results
     * @return uim.cake.Datasource\IEntity|array Results
     */
    protected auto _groupResult(array $row) {
        $defaultAlias = _defaultAlias;
        myResults = $presentAliases = [];
        myOptions = [
            "useSetters":false,
            "markClean":true,
            "markNew":false,
            "guard":false,
        ];

        foreach (_matchingMapColumns as myAlias: myKeys) {
            $matching = _matchingMap[myAlias];
            myResults["_matchingData"][myAlias] = array_combine(
                myKeys,
                array_intersect_key($row, myKeys)
            );
            if (_hydrate) {
                /** @var uim.cake.orm.Table myTable */
                myTable = $matching["instance"];
                myOptions["source"] = myTable.getRegistryAlias();
                /** @var uim.cake.datasources.IEntity $entity */
                $entity = new $matching["entityClass"](myResults["_matchingData"][myAlias], myOptions);
                myResults["_matchingData"][myAlias] = $entity;
            }
        }

        foreach (_map as myTable: myKeys) {
            myResults[myTable] = array_combine(myKeys, array_intersect_key($row, myKeys));
            $presentAliases[myTable] = true;
        }

        // If the default table is not in the results, set
        // it to an empty array so that any contained
        // associations hydrate correctly.
        myResults[$defaultAlias] = myResults[$defaultAlias] ?? [];

        unset($presentAliases[$defaultAlias]);

        foreach (_containMap as $assoc) {
            myAlias = $assoc["nestKey"];

            if ($assoc["canBeJoined"] && empty(_map[myAlias])) {
                continue;
            }

            /** @var uim.cake.orm.Association $instance */
            $instance = $assoc["instance"];

            if (!$assoc["canBeJoined"] && !isset($row[myAlias])) {
                myResults = $instance.defaultRowValue(myResults, $assoc["canBeJoined"]);
                continue;
            }

            if (!$assoc["canBeJoined"]) {
                myResults[myAlias] = $row[myAlias];
            }

            myTarget = $instance.getTarget();
            myOptions["source"] = myTarget.getRegistryAlias();
            unset($presentAliases[myAlias]);

            if ($assoc["canBeJoined"] && _autoFields != false) {
                $hasData = false;
                foreach (myResults[myAlias] as $v) {
                    if ($v  !is null && $v != []) {
                        $hasData = true;
                        break;
                    }
                }

                if (!$hasData) {
                    myResults[myAlias] = null;
                }
            }

            if (_hydrate && myResults[myAlias]  !is null && $assoc["canBeJoined"]) {
                $entity = new $assoc["entityClass"](myResults[myAlias], myOptions);
                myResults[myAlias] = $entity;
            }

            myResults = $instance.transformRow(myResults, myAlias, $assoc["canBeJoined"], $assoc["targetProperty"]);
        }

        foreach ($presentAliases as myAlias: $present) {
            if (!isset(myResults[myAlias])) {
                continue;
            }
            myResults[$defaultAlias][myAlias] = myResults[myAlias];
        }

        if (isset(myResults["_matchingData"])) {
            myResults[$defaultAlias]["_matchingData"] = myResults["_matchingData"];
        }

        myOptions["source"] = _defaultTable.getRegistryAlias();
        if (isset(myResults[$defaultAlias])) {
            myResults = myResults[$defaultAlias];
        }
        if (_hydrate && !(myResults instanceof IEntity)) {
            myResults = new _entityClass(myResults, myOptions);
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
            "items":this.toArray(),
        ];
    }
}
