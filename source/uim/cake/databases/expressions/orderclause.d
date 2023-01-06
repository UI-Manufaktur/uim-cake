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
     */
    protected string _direction;

    /**
     * Constructor
     *
     * @param uim.cake.databases.IExpression|string $field The field to order on.
     * @param string $direction The direction to sort on.
     */
    this($field, $direction) {
        _field = $field;
        _direction = strtolower($direction) == "asc" ? "ASC" : "DESC";
    }


    string sql(ValueBinder aBinder) {
        /** @var uim.cake.databases.IExpression|string $field */
        $field = _field;
        if ($field instanceof Query) {
            $field = sprintf("(%s)", $field.sql($binder));
        } elseif ($field instanceof IExpression) {
            $field = $field.sql($binder);
        }

        return sprintf("%s %s", $field, _direction);
    }


    O traverse(this O)(Closure $callback) {
        if (_field instanceof IExpression) {
            $callback(_field);
            _field.traverse($callback);
        }

        return this;
    }

    /**
     * Create a deep clone of the order clause.
     */
    void __clone() {
        if (_field instanceof IExpression) {
            _field = clone _field;
        }
    }
}
