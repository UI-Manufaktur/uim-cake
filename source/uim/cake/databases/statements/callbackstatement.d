module uim.cake.databases.Statement;

import uim.cake.databases.IDriver;
import uim.cake.databases.IStatement;

/**
 * Wraps a statement in a callback that allows row results
 * to be modified when being fetched.
 *
 * This is used by CakePHP to eagerly load association data.
 */
class CallbackStatement : StatementDecorator
{
    /**
     * A callback function to be applied to results.
     *
     * @var callable
     */
    protected _callback;

    /**
     * Constructor
     *
     * @param uim.cake.databases.IStatement $statement The statement to decorate.
     * @param uim.cake.databases.IDriver aDriver The driver instance used by the statement.
     * @param callable $callback The callback to apply to results before they are returned.
     */
    this(IStatement $statement, IDriver aDriver, callable $callback) {
        super(($statement, $driver);
        _callback = $callback;
    }

    /**
     * Fetch a row from the statement.
     *
     * The result will be processed by the callback when it is not `false`.
     *
     * @param string|int $type Either "num" or "assoc" to indicate the result format you would like.
     * @return array|false
     */
    function fetch($type = super.FETCH_TYPE_NUM) {
        $callback = _callback;
        $row = _statement.fetch($type);

        return $row == false ? $row : $callback($row);
    }

    /**
     * {@inheritDoc}
     *
     * Each row in the result will be processed by the callback when it is not `false.
     */
    function fetchAll($type = super.FETCH_TYPE_NUM) {
        $results = _statement.fetchAll($type);

        return $results != false ? array_map(_callback, $results) : false;
    }
}
