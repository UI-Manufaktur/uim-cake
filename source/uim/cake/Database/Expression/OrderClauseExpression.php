


 *


 * @since         3.0.0
  */
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * An expression object for complex ORDER BY clauses
 */
class OrderClauseExpression : IExpression, FieldInterface
{
    use FieldTrait;

    /**
     * The direction of sorting.
     *
     * @var string
     */
    protected $_direction;

    /**
     * Constructor
     *
     * @param uim.cake.Database\IExpression|string $field The field to order on.
     * @param string $direction The direction to sort on.
     */
    public this($field, $direction) {
        _field = $field;
        _direction = strtolower($direction) == "asc" ? "ASC" : "DESC";
    }


    function sql(ValueBinder $binder): string
    {
        /** @var uim.cake.Database\IExpression|string $field */
        $field = _field;
        if ($field instanceof Query) {
            $field = sprintf("(%s)", $field.sql($binder));
        } elseif ($field instanceof IExpression) {
            $field = $field.sql($binder);
        }

        return sprintf("%s %s", $field, _direction);
    }


    public O traverse(this O)(Closure $callback) {
        if (_field instanceof IExpression) {
            $callback(_field);
            _field.traverse($callback);
        }

        return this;
    }

    /**
     * Create a deep clone of the order clause.
     *
     * @return void
     */
    function __clone() {
        if (_field instanceof IExpression) {
            _field = clone _field;
        }
    }
}
