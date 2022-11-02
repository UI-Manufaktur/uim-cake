module uim.cake.database.Statement;

import uim.cake.database.IDriver;
import uim.cake.database.IStatement;

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
     * @param \Cake\Database\IStatement $statement The statement to decorate.
     * @param \Cake\Database\IDriver myDriver The driver instance used by the statement.
     * @param callable $callback The callback to apply to results before they are returned.
     */
    this(IStatement $statement, IDriver myDriver, callable $callback) {
        super.this($statement, myDriver);
        this._callback = $callback;
    }

    /**
     * Fetch a row from the statement.
     *
     * The result will be processed by the callback when it is not `false`.
     *
     * @param string|int myType Either 'num' or 'assoc' to indicate the result format you would like.
     * @return array|false
     */
    function fetch(myType = super.FETCH_TYPE_NUM) {
        $callback = this._callback;
        $row = this._statement.fetch(myType);

        return $row === false ? $row : $callback($row);
    }

    /**
     * {@inheritDoc}
     *
     * Each row in the result will be processed by the callback when it is not `false.
     */
    function fetchAll(myType = super.FETCH_TYPE_NUM) {
        myResults = this._statement.fetchAll(myType);

        return myResults !== false ? array_map(this._callback, myResults) : false;
    }
}
