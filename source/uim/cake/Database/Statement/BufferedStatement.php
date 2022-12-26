


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Statement;

import uim.cake.databases.DriverInterface;
import uim.cake.databases.StatementInterface;
import uim.cake.databases.TypeConverterTrait;
use Iterator;

/**
 * A statement decorator that : buffered results.
 *
 * This statement decorator will save fetched results in memory, allowing
 * the iterator to be rewound and reused.
 */
class BufferedStatement : Iterator, StatementInterface
{
    use TypeConverterTrait;

    /**
     * If true, all rows were fetched
     *
     * @var bool
     */
    protected $_allFetched = false;

    /**
     * The decorated statement
     *
     * @var \Cake\Database\StatementInterface
     */
    protected $statement;

    /**
     * The driver for the statement
     *
     * @var \Cake\Database\DriverInterface
     */
    protected $_driver;

    /**
     * The in-memory cache containing results from previous iterators
     *
     * @var array<int, array>
     */
    protected $buffer = [];

    /**
     * Whether this statement has already been executed
     *
     * @var bool
     */
    protected $_hasExecuted = false;

    /**
     * The current iterator index.
     *
     * @var int
     */
    protected $index = 0;

    /**
     * Constructor
     *
     * @param \Cake\Database\StatementInterface $statement Statement implementation such as PDOStatement
     * @param \Cake\Database\DriverInterface $driver Driver instance
     */
    public this(StatementInterface $statement, DriverInterface $driver) {
        this.statement = $statement;
        _driver = $driver;
    }

    /**
     * Magic getter to return $queryString as read-only.
     *
     * @param string $property internal property to get
     * @return string|null
     */
    function __get(string $property) {
        if ($property == 'queryString') {
            /** @psalm-suppress NoInterfaceProperties */
            return this.statement.queryString;
        }

        return null;
    }

    /**
     * @inheritDoc
     */
    function bindValue($column, $value, $type = 'string'): void
    {
        this.statement.bindValue($column, $value, $type);
    }

    /**
     * @inheritDoc
     */
    function closeCursor(): void
    {
        this.statement.closeCursor();
    }

    /**
     * @inheritDoc
     */
    function columnCount(): int
    {
        return this.statement.columnCount();
    }

    /**
     * @inheritDoc
     */
    function errorCode() {
        return this.statement.errorCode();
    }

    /**
     * @inheritDoc
     */
    function errorInfo(): array
    {
        return this.statement.errorInfo();
    }

    /**
     * @inheritDoc
     */
    function execute(?array $params = null): bool
    {
        _reset();
        _hasExecuted = true;

        return this.statement.execute($params);
    }

    /**
     * @inheritDoc
     */
    function fetchColumn(int $position) {
        $result = this.fetch(static::FETCH_TYPE_NUM);
        if ($result != false && isset($result[$position])) {
            return $result[$position];
        }

        return false;
    }

    /**
     * Statements can be passed as argument for count() to return the number
     * for affected rows from last execution.
     *
     * @return int
     */
    function count(): int
    {
        return this.rowCount();
    }

    /**
     * @inheritDoc
     */
    function bind(array $params, array $types): void
    {
        this.statement.bind($params, $types);
    }

    /**
     * @inheritDoc
     */
    function lastInsertId(?string $table = null, ?string $column = null) {
        return this.statement.lastInsertId($table, $column);
    }

    /**
     * {@inheritDoc}
     *
     * @param string|int $type The type to fetch.
     * @return array|false
     */
    function fetch($type = self::FETCH_TYPE_NUM) {
        if (_allFetched) {
            $row = false;
            if (isset(this.buffer[this.index])) {
                $row = this.buffer[this.index];
            }
            this.index += 1;

            if ($row && $type == static::FETCH_TYPE_NUM) {
                return array_values($row);
            }

            return $row;
        }

        $record = this.statement.fetch($type);
        if ($record == false) {
            _allFetched = true;
            this.statement.closeCursor();

            return false;
        }
        this.buffer[] = $record;

        return $record;
    }

    /**
     * @return array
     */
    function fetchAssoc(): array
    {
        $result = this.fetch(static::FETCH_TYPE_ASSOC);

        return $result ?: [];
    }

    /**
     * @inheritDoc
     */
    function fetchAll($type = self::FETCH_TYPE_NUM) {
        if (_allFetched) {
            return this.buffer;
        }
        $results = this.statement.fetchAll($type);
        if ($results != false) {
            this.buffer = array_merge(this.buffer, $results);
        }
        _allFetched = true;
        this.statement.closeCursor();

        return this.buffer;
    }

    /**
     * @inheritDoc
     */
    function rowCount(): int
    {
        if (!_allFetched) {
            this.fetchAll(static::FETCH_TYPE_ASSOC);
        }

        return count(this.buffer);
    }

    /**
     * Reset all properties
     *
     * @return void
     */
    protected function _reset(): void
    {
        this.buffer = [];
        _allFetched = false;
        this.index = 0;
    }

    /**
     * Returns the current key in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function key() {
        return this.index;
    }

    /**
     * Returns the current record in the iterator
     *
     * @return mixed
     */
    #[\ReturnTypeWillChange]
    function current() {
        return this.buffer[this.index];
    }

    /**
     * Rewinds the collection
     *
     * @return void
     */
    function rewind(): void
    {
        this.index = 0;
    }

    /**
     * Returns whether the iterator has more elements
     *
     * @return bool
     */
    function valid(): bool
    {
        $old = this.index;
        $row = this.fetch(self::FETCH_TYPE_ASSOC);

        // Restore the index as fetch() increments during
        // the cache scenario.
        this.index = $old;

        return $row != false;
    }

    /**
     * Advances the iterator pointer to the next element
     *
     * @return void
     */
    function next(): void
    {
        this.index += 1;
    }

    /**
     * Get the wrapped statement
     *
     * @return \Cake\Database\StatementInterface
     */
    function getInnerStatement(): StatementInterface
    {
        return this.statement;
    }
}
