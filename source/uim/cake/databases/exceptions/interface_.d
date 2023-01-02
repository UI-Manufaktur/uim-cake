module uim.cake.databases;

use Closure;

// An interface used by Expression objects.
interface IExpression {
    /**
     * Converts the Node into a SQL string fragment.
     *
     * @param uim.cake.databases.ValueBinder aBinder Parameter binder
     */
    string sql(ValueBinder aBinder);

    /**
     * Iterates over each part of the expression recursively for every
     * level of the expressions tree and executes the $callback callable
     * passing as first parameter the instance of the expression currently
     * being iterated.
     *
     * @param \Closure $callback The callable to apply to all nodes.
     * @return this
     */
    IExpression traverse(Closure aCallback);
}
