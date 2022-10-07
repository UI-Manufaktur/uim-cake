module uim.cake.database.Statement;

import uim.cake.database.IDriver;
import uim.cake.database.IStatement;
import uim.cake.database.TypeConverterTrait;
use Iterator;

/**
 * A statement decorator that : buffered results.
 *
 * This statement decorator will save fetched results in memory, allowing
 * the iterator to be rewound and reused.
 */
class BufferedStatement : Iterator, IStatement
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
     * @var \Cake\Database\IStatement
     */
    protected $statement;

    /**
     * The driver for the statement
     *
     * @var \Cake\Database\IDriver
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
     * @param \Cake\Database\IStatement $statement Statement implementation such as PDOStatement
     * @param \Cake\Database\IDriver myDriver Driver instance
     */
    this(IStatement $statement, IDriver myDriver)
    {
        this.statement = $statement;
        this._driver = myDriver;
    }

    /**
     * Magic getter to return myQueryString as read-only.
     *
     * @param string $property internal property to get
     * @return string|null
     */
    auto __get(string $property)
    {
        if ($property === 'queryString') {
            /** @psalm-suppress NoInterfaceProperties */
            return this.statement.queryString;
        }

        return null;
    }


    function bindValue($column, myValue, myType = 'string'): void
    {
        this.statement.bindValue($column, myValue, myType);
    }


    function closeCursor(): void
    {
        this.statement.closeCursor();
    }


    function columnCount(): int
    {
        return this.statement.columnCount();
    }


    function errorCode() {
        return this.statement.errorCode();
    }


    function errorInfo(): array
    {
        return this.statement.errorInfo();
    }


    auto execute(?array myParams = null): bool
    {
        this._reset();
        this._hasExecuted = true;

        return this.statement.execute(myParams);
    }


    function fetchColumn(int $position)
    {
        myResult = this.fetch(static::FETCH_TYPE_NUM);
        if (myResult !== false && isset(myResult[$position])) {
            return myResult[$position];
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


    function bind(array myParams, array myTypes): void
    {
        this.statement.bind(myParams, myTypes);
    }


    function lastInsertId(?string myTable = null, ?string $column = null)
    {
        return this.statement.lastInsertId(myTable, $column);
    }

    /**
     * {@inheritDoc}
     *
     * @param string|int myType The type to fetch.
     * @return array|false
     */
    function fetch(myType = self::FETCH_TYPE_NUM)
    {
        if (this._allFetched) {
            $row = false;
            if (isset(this.buffer[this.index])) {
                $row = this.buffer[this.index];
            }
            this.index += 1;

            if ($row && myType === static::FETCH_TYPE_NUM) {
                return array_values($row);
            }

            return $row;
        }

        $record = this.statement.fetch(myType);
        if ($record === false) {
            this._allFetched = true;
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
        myResult = this.fetch(static::FETCH_TYPE_ASSOC);

        return myResult ?: [];
    }


    function fetchAll(myType = self::FETCH_TYPE_NUM)
    {
        if (this._allFetched) {
            return this.buffer;
        }
        myResults = this.statement.fetchAll(myType);
        if (myResults !== false) {
            this.buffer = array_merge(this.buffer, myResults);
        }
        this._allFetched = true;
        this.statement.closeCursor();

        return this.buffer;
    }


    function rowCount(): int
    {
        if (!this._allFetched) {
            this.fetchAll(static::FETCH_TYPE_ASSOC);
        }

        return count(this.buffer);
    }

    /**
     * Reset all properties
     *
     * @return void
     */
    protected auto _reset(): void
    {
        this.buffer = [];
        this._allFetched = false;
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

        return $row !== false;
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
     * @return \Cake\Database\IStatement
     */
    auto getInnerStatement(): IStatement
    {
        return this.statement;
    }
}
