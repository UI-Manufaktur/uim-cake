module uim.cake.database;

use Closure;

/**
 * An interface used by Expression objects.
 */
interface IExpression
{
    /**
     * Converts the Node into a SQL string fragment.
     *
     * @param \Cake\Database\ValueBinder $binder Parameter binder
     * @return string
     */
    string sql(ValueBinder $binder);

    /**
     * Iterates over each part of the expression recursively for every
     * level of the expressions tree and executes the $callback callable
     * passing as first parameter the instance of the expression currently
     * being iterated.
     *
     * @param \Closure $callback The callable to apply to all nodes.
     * @return this
     */
    function traverse(Closure $callback);
}
