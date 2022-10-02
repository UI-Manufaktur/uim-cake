module uim.cake.database.Statement;

import uim.cake.core.Exception\CakeException;
import uim.cake.database.IDriver;
use PDO;
use PDOStatement as Statement;

/**
 * Decorator for \PDOStatement class mainly used for converting human readable
 * fetch modes into PDO constants.
 */
class PDOStatement : StatementDecorator
{
    /**
     * PDOStatement instance
     *
     * @var \PDOStatement
     */
    protected $_statement;

    /**
     * Constructor
     *
     * @param \PDOStatement $statement Original statement to be decorated.
     * @param \Cake\Database\IDriver myDriver Driver instance.
     */
    this(Statement $statement, IDriver myDriver)
    {
        this._statement = $statement;
        this._driver = myDriver;
    }

    /**
     * Magic getter to return PDOStatement::myQueryString as read-only.
     *
     * @param string $property internal property to get
     * @return string|null
     */
    auto __get(string $property)
    {
        if ($property === 'queryString' && isset(this._statement.queryString)) {
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
     * You can pass PDO compatible constants for binding values with a type or optionally
     * any type name registered in the Type class. Any value will be converted to the valid type
     * representation if needed.
     *
     * It is not allowed to combine positional and named variables in the same statement
     *
     * ### Examples:
     *
     * ```
     * $statement.bindValue(1, 'a title');
     * $statement.bindValue(2, 5, PDO::INT);
     * $statement.bindValue('active', true, 'boolean');
     * $statement.bindValue(5, new \DateTime(), 'date');
     * ```
     *
     * @param string|int $column name or param position to be bound
     * @param mixed myValue The value to bind to variable in query
     * @param string|int|null myType PDO type or name of configured Type class
     * @return void
     */
    function bindValue($column, myValue, myType = 'string'): void
    {
        if (myType === null) {
            myType = 'string';
        }
        if (!is_int(myType)) {
            [myValue, myType] = this.cast(myValue, myType);
        }
        this._statement.bindValue($column, myValue, myType);
    }

    /**
     * Returns the next row for the result set after executing this statement.
     * Rows can be fetched to contain columns as names or positions. If no
     * rows are left in result set, this method will return false
     *
     * ### Example:
     *
     * ```
     *  $statement = myConnection.prepare('SELECT id, title from articles');
     *  $statement.execute();
     *  print_r($statement.fetch('assoc')); // will show ['id' => 1, 'title' => 'a title']
     * ```
     *
     * @param string|int myType 'num' for positional columns, assoc for named columns
     * @return mixed Result array containing columns and values or false if no results
     * are left
     */
    function fetch(myType = super.FETCH_TYPE_NUM)
    {
        if (myType === static::FETCH_TYPE_NUM) {
            return this._statement.fetch(PDO::FETCH_NUM);
        }
        if (myType === static::FETCH_TYPE_ASSOC) {
            return this._statement.fetch(PDO::FETCH_ASSOC);
        }
        if (myType === static::FETCH_TYPE_OBJ) {
            return this._statement.fetch(PDO::FETCH_OBJ);
        }

        if (!is_int(myType)) {
            throw new CakeException(sprintf(
                'Fetch type for PDOStatement must be an integer, found `%s` instead',
                getTypeName(myType)
            ));
        }

        return this._statement.fetch(myType);
    }

    /**
     * Returns an array with all rows resulting from executing this statement
     *
     * ### Example:
     *
     * ```
     *  $statement = myConnection.prepare('SELECT id, title from articles');
     *  $statement.execute();
     *  print_r($statement.fetchAll('assoc')); // will show [0 => ['id' => 1, 'title' => 'a title']]
     * ```
     *
     * @param string|int myType num for fetching columns as positional keys or assoc for column names as keys
     * @return array|false list of all results from database for this statement, false on failure
     * @psalm-assert string myType
     */
    function fetchAll(myType = super.FETCH_TYPE_NUM)
    {
        if (myType === static::FETCH_TYPE_NUM) {
            return this._statement.fetchAll(PDO::FETCH_NUM);
        }
        if (myType === static::FETCH_TYPE_ASSOC) {
            return this._statement.fetchAll(PDO::FETCH_ASSOC);
        }
        if (myType === static::FETCH_TYPE_OBJ) {
            return this._statement.fetchAll(PDO::FETCH_OBJ);
        }

        if (!is_int(myType)) {
            throw new CakeException(sprintf(
                'Fetch type for PDOStatement must be an integer, found `%s` instead',
                getTypeName(myType)
            ));
        }

        return this._statement.fetchAll(myType);
    }
}
