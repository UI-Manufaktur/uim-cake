


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

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
    function sql(ValueBinder $binder): string;

    /**
     * Iterates over each part of the expression recursively for every
     * level of the expressions tree and executes the $callback callable
     * passing as first parameter the instance of the expression currently
     * being iterated.
     *
     * @param \Closure $callback The callable to apply to all nodes.
     * @return this
     */
    public O traverse(this O)(Closure $callback);
}
