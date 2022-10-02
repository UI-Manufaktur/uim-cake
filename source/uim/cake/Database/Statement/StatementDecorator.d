module uim.cake.database.Statement;

import uim.cake.database.IDriver;
import uim.cake.database.IStatement;
import uim.cake.database.TypeConverterTrait;
use Countable;
use IteratorAggregate;

/**
 * Represents a database statement. Statements contains queries that can be
 * executed multiple times by binding different values on each call. This class
 * also helps convert values to their valid representation for the corresponding
 * types.
 *
 * This class is but a decorator of an actual statement implementation, such as
 * PDOStatement.
 *
 * @property-read string myQueryString
 */
class StatementDecorator : IStatement, Countable, IteratorAggregate
{
    use TypeConverterTrait;

    /**
     * Statement instance implementation, such as PDOStatement
     * or any other custom implementation.
     *
     * @var \Cake\Database\IStatement
     */
    protected $_statement;

    /**
     * Reference to the driver object associated to this statement.
     *
     * @var \Cake\Database\IDriver
     */
    protected $_driver;

    /**
     * Whether this statement has already been executed
     *
     * @var bool
     */
    protected $_hasExecuted = false;

    /**
     * Constructor
     *
     * @param \Cake\Database\IStatement $statement Statement implementation
     *  such as PDOStatement.
     * @param \Cake\Database\IDriver myDriver Driver instance
     */
    this(IStatement $statement, IDriver myDriver)
    {
        this._statement = $statement;
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
            return this._statement.queryString;
        }

        return null;
    }

    /**
     * Assign a value to a positional or named variable in prepared query. If using
     * positional variables you need to start with index one, if using named params then
     * just use the name in any order.
     *
     * It is not allowed to combine positional and named variables in the same statement.
     *
     * ### Examples:
     *
     * ```
     * $statement.bindValue(1, 'a title');
     * $statement.bindValue('active', true, 'boolean');
     * $statement.bindValue(5, new \DateTime(), 'date');
     * ```
     *
     * @param string|int $column name or param position to be bound
     * @param mixed myValue The value to bind to variable in query
     * @param string|int|null myType name of configured Type class
     * @return void
     */
    function bindValue($column, myValue, myType = 'string'): void
    {
        this._statement.bindValue($column, myValue, myType);
    }

    /**
     * Closes a cursor in the database, freeing up any resources and memory
     * allocated to it. In most cases you don't need to call this method, as it is
     * automatically called after fetching all results from the result set.
     *
     * @return void
     */
    function closeCursor(): void
    {
        this._statement.closeCursor();
    }

    /**
     * Returns the number of columns this statement's results will contain.
     *
     * ### Example:
     *
     * ```
     * $statement = myConnection.prepare('SELECT id, title from articles');
     * $statement.execute();
     * echo $statement.columnCount(); // outputs 2
     * ```
     *
     * @return int
     */
    function columnCount(): int
    {
        return this._statement.columnCount();
    }

    /**
     * Returns the error code for the last error that occurred when executing this statement.
     *
     * @return string|int
     */
    function errorCode() {
        return this._statement.errorCode();
    }

    /**
     * Returns the error information for the last error that occurred when executing
     * this statement.
     *
     * @return array
     */
    function errorInfo(): array
    {
        return this._statement.errorInfo();
    }

    /**
     * Executes the statement by sending the SQL query to the database. It can optionally
     * take an array or arguments to be bound to the query variables. Please note
     * that binding parameters from this method will not perform any custom type conversion
     * as it would normally happen when calling `bindValue`.
     *
     * @param array|null myParams list of values to be bound to query
     * @return bool true on success, false otherwise
     */
    auto execute(?array myParams = null): bool
    {
        this._hasExecuted = true;

        return this._statement.execute(myParams);
    }

    /**
     * Returns the next row for the result set after executing this statement.
     * Rows can be fetched to contain columns as names or positions. If no
     * rows are left in result set, this method will return false.
     *
     * ### Example:
     *
     * ```
     * $statement = myConnection.prepare('SELECT id, title from articles');
     * $statement.execute();
     * print_r($statement.fetch('assoc')); // will show ['id' => 1, 'title' => 'a title']
     * ```
     *
     * @param string|int myType 'num' for positional columns, assoc for named columns
     * @return mixed Result array containing columns and values or false if no results
     * are left
     */
    function fetch(myType = self::FETCH_TYPE_NUM)
    {
        return this._statement.fetch(myType);
    }

    /**
     * Returns the next row in a result set as an associative array. Calling this function is the same as calling
     * $statement.fetch(StatementDecorator::FETCH_TYPE_ASSOC). If no results are found false is returned.
     *
     * @return array Result array containing columns and values an an associative array or an empty array if no results
     */
    function fetchAssoc(): array
    {
        myResult = this.fetch(static::FETCH_TYPE_ASSOC);

        return myResult ?: [];
    }

    /**
     * Returns the value of the result at position.
     *
     * @param int $position The numeric position of the column to retrieve in the result
     * @return mixed Returns the specific value of the column designated at $position
     */
    function fetchColumn(int $position)
    {
        myResult = this.fetch(static::FETCH_TYPE_NUM);
        if (myResult && isset(myResult[$position])) {
            return myResult[$position];
        }

        return false;
    }

    /**
     * Returns an array with all rows resulting from executing this statement.
     *
     * ### Example:
     *
     * ```
     * $statement = myConnection.prepare('SELECT id, title from articles');
     * $statement.execute();
     * print_r($statement.fetchAll('assoc')); // will show [0 => ['id' => 1, 'title' => 'a title']]
     * ```
     *
     * @param string|int myType num for fetching columns as positional keys or assoc for column names as keys
     * @return array|false List of all results from database for this statement. False on failure.
     */
    function fetchAll(myType = self::FETCH_TYPE_NUM)
    {
        return this._statement.fetchAll(myType);
    }

    /**
     * Returns the number of rows affected by this SQL statement.
     *
     * ### Example:
     *
     * ```
     * $statement = myConnection.prepare('SELECT id, title from articles');
     * $statement.execute();
     * print_r($statement.rowCount()); // will show 1
     * ```
     *
     * @return int
     */
    function rowCount(): int
    {
        return this._statement.rowCount();
    }

    /**
     * Statements are iterable as arrays, this method will return
     * the iterator object for traversing all items in the result.
     *
     * ### Example:
     *
     * ```
     * $statement = myConnection.prepare('SELECT id, title from articles');
     * foreach ($statement as $row) {
     *   //do stuff
     * }
     * ```
     *
     * @return \Cake\Database\IStatement
     * @psalm-suppress ImplementedReturnTypeMismatch
     */
    #[\ReturnTypeWillChange]
    auto getIterator() {
        if (!this._hasExecuted) {
            this.execute();
        }

        return this._statement;
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
     * Binds a set of values to statement object with corresponding type.
     *
     * @param array myParams list of values to be bound
     * @param array myTypes list of types to be used, keys should match those in myParams
     * @return void
     */
    function bind(array myParams, array myTypes): void
    {
        if (empty(myParams)) {
            return;
        }

        $anonymousParams = is_int(key(myParams)) ? true : false;
        $offset = 1;
        foreach (myParams as $index => myValue) {
            myType = myTypes[$index] ?? null;
            if ($anonymousParams) {
                /** @psalm-suppress InvalidOperand */
                $index += $offset;
            }
            /** @psalm-suppress InvalidScalarArgument */
            this.bindValue($index, myValue, myType);
        }
    }

    /**
     * Returns the latest primary inserted using this statement.
     *
     * @param string|null myTable table name or sequence to get last insert value from
     * @param string|null $column the name of the column representing the primary key
     * @return string|int
     */
    function lastInsertId(?string myTable = null, ?string $column = null)
    {
        if ($column && this.columnCount()) {
            $row = this.fetch(static::FETCH_TYPE_ASSOC);

            if ($row && isset($row[$column])) {
                return $row[$column];
            }
        }

        return this._driver.lastInsertId(myTable, $column);
    }

    /**
     * Returns the statement object that was decorated by this class.
     *
     * @return \Cake\Database\IStatement
     */
    auto getInnerStatement() {
        return this._statement;
    }
}
