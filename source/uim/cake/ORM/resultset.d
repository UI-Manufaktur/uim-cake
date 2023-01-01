module uim.cake.ORM;

import uim.cake.Collection\Collection;
import uim.cake.Collection\CollectionTrait;
import uim.cake.databases.exceptions.DatabaseException;
import uim.cake.databases.StatementInterface;
import uim.cake.datasources.EntityInterface;
import uim.cake.datasources.IResultSet;
use SplFixedArray;

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
     * @var uim.cake.databases.StatementInterface
     */
    protected $_statement;

    /**
     * Points to the next record number that should be fetched
     *
     */
    protected int $_index = 0;

    /**
     * Last record fetched from the statement
     *
     * @var object|array
     */
    protected $_current;

    /**
     * Default table instance
     *
     * @var uim.cake.orm.Table
     */
    protected $_defaultTable;

    /**
     * The default table alias
     *
     */
    protected string $_defaultAlias;

    /**
     * List of associations that should be placed under the `_matchingData`
     * result key.
     *
     * @var array<string, mixed>
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
     * @var array<string, mixed>
     */
    protected $_map = [];

    /**
     * List of matching associations and the column keys to expect
     * from each of them.
     *
     * @var array<string, mixed>
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
     */
    protected bool $_hydrate = true;

    /**
     * Tracks value of $_autoFields property of $query passed to constructor.
     *
     * @var bool|null
     */
    protected $_autoFields;

    /**
     * The fully namespaced name of the class to use for hydrating results
     *
     */
    protected string $_entityClass;

    /**
     * Whether to buffer results fetched from the statement
     *
     */
    protected bool $_useBuffering = true;

    /**
     * Holds the count of records in this result set
     *
     */
    protected int $_count;

    /**
     * The Database driver object.
     *
     * Cached in a property to avoid multiple calls to the same function.
     *
     * @var uim.cake.databases.DriverInterface
     */
    protected $_driver;

    /**
     * Constructor
     *
     * @param uim.cake.orm.Query $query Query from where results come
     * @param uim.cake.databases.StatementInterface $statement The statement to fetch from
     */
    this(Query $query, StatementInterface $statement) {
        $repository = $query.getRepository();
        _statement = $statement;
        _driver = $query.getConnection().getDriver();
        _defaultTable = $repository;
        _calculateAssociationMap($query);
        _hydrate = $query.isHydrationEnabled();
        _entityClass = $repository.getEntityClass();
        _useBuffering = $query.isBufferedResultsEnabled();
        _defaultAlias = _defaultTable.getAlias();
        _calculateColumnMap($query);
        _autoFields = $query.isAutoFieldsEnabled();

        if (_useBuffering) {
            $count = this.count();
            _results = new SplFixedArray($count);
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
     *
     */
    int key(): int
    {
        return _index;
    }

    /**
     * Advances the iterator pointer to the next record
     *
     * Part of Iterator interface.
     */
    void next(): void
    {
        _index++;
    }

    /**
     * Rewinds a ResultSet.
     *
     * Part of Iterator interface.
     *
     * @throws uim.cake.databases.exceptions.DatabaseException
     */
    void rewind(): void
    {
        if (_index == 0) {
            return;
        }

        if (!_useBuffering) {
            $msg = "You cannot rewind an un-buffered ResultSet~ "
                ~ "Use Query::bufferResults() to get a buffered ResultSet.";
            throw new DatabaseException($msg);
        }

        _index = 0;
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
        if (_useBuffering) {
            $valid = _index < _count;
            if ($valid && _results[_index] != null) {
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
        if (!$valid && _statement != null) {
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
        foreach (this as $result) {
            if (_statement != null && !_useBuffering) {
                _statement.closeCursor();
            }

            return $result;
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
        return serialize(__serialize());
    }

    /**
     * Serializes a resultset.
     */
    array __serialize(): array
    {
        if (!_useBuffering) {
            $msg = "You cannot serialize an un-buffered ResultSet~ "
                ~ "Use Query::bufferResults() to get a buffered ResultSet.";
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
     * @param string $serialized Serialized object
     */
    void unserialize($serialized) {
        __unserialize((array)(unserialize($serialized) ?: []));
    }

    /**
     * Unserializes a resultset.
     *
     * @param array $data Data array.
     */
    void __unserialize(array $data): void
    {
        _results = SplFixedArray::fromArray($data);
        _useBuffering = true;
        _count = _results.count();
    }

    /**
     * Gives the number of rows in the result set.
     *
     * Part of the Countable interface.
     *
     */
    int count(): int
    {
        if (_count != null) {
            return _count;
        }
        if (_statement != null) {
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
     * @param uim.cake.orm.Query $query The query from where to derive the associations
     */
    protected void _calculateAssociationMap(Query $query): void
    {
        $map = $query.getEagerLoader().associationsMap(_defaultTable);
        _matchingMap = (new Collection($map))
            .match(["matching": true])
            .indexBy("alias")
            .toArray();

        _containMap = (new Collection(array_reverse($map)))
            .match(["matching": false])
            .indexBy("nestKey")
            .toArray();
    }

    /**
     * Creates a map of row keys out of the query select clause that can be
     * used to hydrate nested result sets more quickly.
     *
     * @param uim.cake.orm.Query $query The query from where to derive the column map
     */
    protected void _calculateColumnMap(Query $query): void
    {
        $map = [];
        foreach ($query.clause("select") as $key: $field) {
            $key = trim($key, ""`[]");

            if (strpos($key, "__") <= 0) {
                $map[_defaultAlias][$key] = $key;
                continue;
            }

            $parts = explode("__", $key, 2);
            $map[$parts[0]][$key] = $parts[1];
        }

        foreach (_matchingMap as $alias: $assoc) {
            if (!isset($map[$alias])) {
                continue;
            }
            _matchingMapColumns[$alias] = $map[$alias];
            unset($map[$alias]);
        }

        _map = $map;
    }

    /**
     * Helper function to fetch the next result from the statement or
     * seeded results.
     *
     * @return mixed
     */
    protected function _fetchResult() {
        if (_statement == null) {
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
     * @return uim.cake.Datasource\EntityInterface|array Results
     */
    protected function _groupResult(array $row) {
        $defaultAlias = _defaultAlias;
        $results = $presentAliases = [];
        $options = [
            "useSetters": false,
            "markClean": true,
            "markNew": false,
            "guard": false,
        ];

        foreach (_matchingMapColumns as $alias: $keys) {
            $matching = _matchingMap[$alias];
            $results["_matchingData"][$alias] = array_combine(
                $keys,
                array_intersect_key($row, $keys)
            );
            if (_hydrate) {
                /** @var uim.cake.orm.Table $table */
                $table = $matching["instance"];
                $options["source"] = $table.getRegistryAlias();
                /** @var uim.cake.datasources.EntityInterface $entity */
                $entity = new $matching["entityClass"]($results["_matchingData"][$alias], $options);
                $results["_matchingData"][$alias] = $entity;
            }
        }

        foreach (_map as $table: $keys) {
            $results[$table] = array_combine($keys, array_intersect_key($row, $keys));
            $presentAliases[$table] = true;
        }

        // If the default table is not in the results, set
        // it to an empty array so that any contained
        // associations hydrate correctly.
        $results[$defaultAlias] = $results[$defaultAlias] ?? [];

        unset($presentAliases[$defaultAlias]);

        foreach (_containMap as $assoc) {
            $alias = $assoc["nestKey"];

            if ($assoc["canBeJoined"] && empty(_map[$alias])) {
                continue;
            }

            /** @var uim.cake.orm.Association $instance */
            $instance = $assoc["instance"];

            if (!$assoc["canBeJoined"] && !isset($row[$alias])) {
                $results = $instance.defaultRowValue($results, $assoc["canBeJoined"]);
                continue;
            }

            if (!$assoc["canBeJoined"]) {
                $results[$alias] = $row[$alias];
            }

            $target = $instance.getTarget();
            $options["source"] = $target.getRegistryAlias();
            unset($presentAliases[$alias]);

            if ($assoc["canBeJoined"] && _autoFields != false) {
                $hasData = false;
                foreach ($results[$alias] as $v) {
                    if ($v != null && $v != []) {
                        $hasData = true;
                        break;
                    }
                }

                if (!$hasData) {
                    $results[$alias] = null;
                }
            }

            if (_hydrate && $results[$alias] != null && $assoc["canBeJoined"]) {
                $entity = new $assoc["entityClass"]($results[$alias], $options);
                $results[$alias] = $entity;
            }

            $results = $instance.transformRow($results, $alias, $assoc["canBeJoined"], $assoc["targetProperty"]);
        }

        foreach ($presentAliases as $alias: $present) {
            if (!isset($results[$alias])) {
                continue;
            }
            $results[$defaultAlias][$alias] = $results[$alias];
        }

        if (isset($results["_matchingData"])) {
            $results[$defaultAlias]["_matchingData"] = $results["_matchingData"];
        }

        $options["source"] = _defaultTable.getRegistryAlias();
        if (isset($results[$defaultAlias])) {
            $results = $results[$defaultAlias];
        }
        if (_hydrate && !($results instanceof EntityInterface)) {
            $results = new _entityClass($results, $options);
        }

        return $results;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    function __debugInfo() {
        $currentIndex = _index;
        // toArray() adjusts the current index, so we have to reset it
        $items = this.toArray();
        _index = $currentIndex;

        return [
            "items": $items,
        ];
    }
}