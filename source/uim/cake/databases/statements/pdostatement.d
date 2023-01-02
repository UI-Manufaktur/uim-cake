module uim.cake.databases.Statement;

import uim.cake.core.exceptions.CakeException;
import uim.cake.databases.IDriver;
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
     * @param uim.cake.databases.IDriver $driver Driver instance.
     */
    this(Statement $statement, IDriver $driver) {
        _statement = $statement;
        _driver = $driver;
    }

    /**
     * Magic getter to return PDOStatement::$queryString as read-only.
     *
     * @param string $property internal property to get
     * @return string|null
     */
    function __get(string $property) {
        if ($property == "queryString" && isset(_statement.queryString)) {
            /** @psalm-suppress NoInterfaceProperties */
            return _statement.queryString;
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
     * $statement.bindValue(1, "a title");
     * $statement.bindValue(2, 5, PDO::INT);
     * $statement.bindValue("active", true, "boolean");
     * $statement.bindValue(5, new \DateTime(), "date");
     * ```
     *
     * @param string|int $column name or param position to be bound
     * @param mixed $value The value to bind to variable in query
     * @param string|int|null $type PDO type or name of configured Type class
     */
    void bindValue($column, $value, $type = "string"): void
    {
        if ($type == null) {
            $type = "string";
        }
        if (!is_int($type)) {
            [$value, $type] = this.cast($value, $type);
        }
        _statement.bindValue($column, $value, $type);
    }

    /**
     * Returns the next row for the result set after executing this statement.
     * Rows can be fetched to contain columns as names or positions. If no
     * rows are left in result set, this method will return false
     *
     * ### Example:
     *
     * ```
     *  $statement = $connection.prepare("SELECT id, title from articles");
     *  $statement.execute();
     *  print_r($statement.fetch("assoc")); // will show ["id": 1, "title": "a title"]
     * ```
     *
     * @param string|int $type "num" for positional columns, assoc for named columns
     * @return mixed Result array containing columns and values or false if no results
     * are left
     */
    function fetch($type = super.FETCH_TYPE_NUM) {
        if ($type == static::FETCH_TYPE_NUM) {
            return _statement.fetch(PDO::FETCH_NUM);
        }
        if ($type == static::FETCH_TYPE_ASSOC) {
            return _statement.fetch(PDO::FETCH_ASSOC);
        }
        if ($type == static::FETCH_TYPE_OBJ) {
            return _statement.fetch(PDO::FETCH_OBJ);
        }

        if (!is_int($type)) {
            throw new CakeException(sprintf(
                "Fetch type for PDOStatement must be an integer, found `%s` instead",
                getTypeName($type)
            ));
        }

        return _statement.fetch($type);
    }

    /**
     * Returns an array with all rows resulting from executing this statement
     *
     * ### Example:
     *
     * ```
     *  $statement = $connection.prepare("SELECT id, title from articles");
     *  $statement.execute();
     *  print_r($statement.fetchAll("assoc")); // will show [0: ["id": 1, "title": "a title"]]
     * ```
     *
     * @param string|int $type num for fetching columns as positional keys or assoc for column names as keys
     * @return array|false list of all results from database for this statement, false on failure
     * @psalm-assert string $type
     */
    function fetchAll($type = super.FETCH_TYPE_NUM) {
        if ($type == static::FETCH_TYPE_NUM) {
            return _statement.fetchAll(PDO::FETCH_NUM);
        }
        if ($type == static::FETCH_TYPE_ASSOC) {
            return _statement.fetchAll(PDO::FETCH_ASSOC);
        }
        if ($type == static::FETCH_TYPE_OBJ) {
            return _statement.fetchAll(PDO::FETCH_OBJ);
        }

        if (!is_int($type)) {
            throw new CakeException(sprintf(
                "Fetch type for PDOStatement must be an integer, found `%s` instead",
                getTypeName($type)
            ));
        }

        return _statement.fetchAll($type);
    }
}
