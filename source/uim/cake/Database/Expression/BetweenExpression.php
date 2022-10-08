module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.Type\ExpressionTypeCasterTrait;
import uim.cake.database.ValueBinder;
use Closure;

/**
 * An expression object that represents a SQL BETWEEN snippet
 */
class BetweenExpression : IExpression, FieldInterface
{
    use ExpressionTypeCasterTrait;
    use FieldTrait;

    /**
     * The first value in the expression
     *
     * @var mixed
     */
    protected $_from;

    /**
     * The second value in the expression
     *
     * @var mixed
     */
    protected $_to;

    /**
     * The data type for the from and to arguments
     *
     * @var mixed
     */
    protected $_type;

    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|string myField The field name to compare for values inbetween the range.
     * @param mixed $from The initial value of the range.
     * @param mixed $to The ending value in the comparison range.
     * @param string|null myType The data type name to bind the values with.
     */
    this(myField, $from, $to, myType = null) {
        if (myType !== null) {
            $from = this._castToExpression($from, myType);
            $to = this._castToExpression($to, myType);
        }

        this._field = myField;
        this._from = $from;
        this._to = $to;
        this._type = myType;
    }


    function sql(ValueBinder $binder): string
    {
        $parts = [
            'from' => this._from,
            'to' => this._to,
        ];

        /** @var \Cake\Database\IExpression|string myField */
        myField = this._field;
        if (myField instanceof IExpression) {
            myField = myField.sql($binder);
        }

        foreach ($parts as myName => $part) {
            if ($part instanceof IExpression) {
                $parts[myName] = $part.sql($binder);
                continue;
            }
            $parts[myName] = this._bindValue($part, $binder, this._type);
        }

        return sprintf('%s BETWEEN %s AND %s', myField, $parts['from'], $parts['to']);
    }


    function traverse(Closure $callback) {
        foreach ([this._field, this._from, this._to] as $part) {
            if ($part instanceof IExpression) {
                $callback($part);
            }
        }

        return this;
    }

    /**
     * Registers a value in the placeholder generator and returns the generated placeholder
     *
     * @param mixed myValue The value to bind
     * @param \Cake\Database\ValueBinder $binder The value binder to use
     * @param string myType The type of myValue
     * @return string generated placeholder
     */
    protected auto _bindValue(myValue, $binder, myType): string
    {
        $placeholder = $binder.placeholder('c');
        $binder.bind($placeholder, myValue, myType);

        return $placeholder;
    }

    /**
     * Do a deep clone of this expression.
     *
     * @return void
     */
    auto __clone() {
        foreach (['_field', '_from', '_to'] as $part) {
            if (this.{$part} instanceof IExpression) {
                this.{$part} = clone this.{$part};
            }
        }
    }
}
