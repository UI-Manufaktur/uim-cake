module uim.cake.databases.expressions;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * An expression object that represents an expression with only a single operand.
 */
class UnaryExpression : IExpression
{
    /**
     * Indicates that the operation is in pre-order
     *
     * @var int
     */
    public const PREFIX = 0;

    /**
     * Indicates that the operation is in post-order
     *
     * @var int
     */
    public const POSTFIX = 1;

    /**
     * The operator this unary expression represents
     *
     * @var string
     */
    protected $_operator;

    /**
     * Holds the value which the unary expression operates
     *
     * @var mixed
     */
    protected $_value;

    /**
     * Where to place the operator
     *
     * @var int
     */
    protected $position;

    /**
     * Constructor
     *
     * @param string $operator The operator to used for the expression
     * @param mixed myValue the value to use as the operand for the expression
     * @param int $position either UnaryExpression::PREFIX or UnaryExpression::POSTFIX
     */
    this(string $operator, myValue, $position = self::PREFIX) {
        this._operator = $operator;
        this._value = myValue;
        this.position = $position;
    }


    function sql(ValueBinder $binder): string
    {
        $operand = this._value;
        if ($operand instanceof IExpression) {
            $operand = $operand.sql($binder);
        }

        if (this.position === self::POSTFIX) {
            return '(' . $operand . ') ' . this._operator;
        }

        return this._operator . ' (' . $operand . ')';
    }


    function traverse(Closure $callback) {
        if (this._value instanceof IExpression) {
            $callback(this._value);
            this._value.traverse($callback);
        }

        return this;
    }

    /**
     * Perform a deep clone of the inner expression.
     *
     * @return void
     */
    auto __clone() {
        if (this._value instanceof IExpression) {
            this._value = clone this._value;
        }
    }
}
