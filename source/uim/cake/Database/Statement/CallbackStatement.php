


 *


 * @since         3.0.0
  */
module uim.cake.databases.Statement;

import uim.cake.databases.DriverInterface;
import uim.cake.databases.StatementInterface;

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
    protected $_callback;

    /**
     * Constructor
     *
     * @param uim.cake.Database\StatementInterface $statement The statement to decorate.
     * @param uim.cake.Database\DriverInterface $driver The driver instance used by the statement.
     * @param callable $callback The callback to apply to results before they are returned.
     */
    public this(StatementInterface $statement, DriverInterface $driver, callable $callback) {
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
    function fetch($type = parent::FETCH_TYPE_NUM) {
        $callback = _callback;
        $row = _statement.fetch($type);

        return $row == false ? $row : $callback($row);
    }

    /**
     * {@inheritDoc}
     *
     * Each row in the result will be processed by the callback when it is not `false.
     */
    function fetchAll($type = parent::FETCH_TYPE_NUM) {
        $results = _statement.fetchAll($type);

        return $results != false ? array_map(_callback, $results) : false;
    }
}
