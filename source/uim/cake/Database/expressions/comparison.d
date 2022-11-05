module uim.baklava.databases.expressions;

import uim.baklava.databases.exceptions\DatabaseException;
import uim.baklava.databases.IExpression;
import uim.baklava.databases.Type\ExpressionTypeCasterTrait;
import uim.baklava.databases.ValueBinder;
use Closure;

/**
 * A Comparison is a type of query expression that represents an operation
 * involving a field an operator and a value. In its most common form the
 * string representation of a comparison is `field = value`
 */
class ComparisonExpression : IExpression, FieldInterface
{
    use ExpressionTypeCasterTrait;
    use FieldTrait;

    /**
     * The value to be used in the right hand side of the operation
     *
     * @var mixed
     */
    protected $_value;

    /**
     * The type to be used for casting the value to a database representation
     *
     * @var string|null
     */
    protected $_type;

    /**
     * The operator used for comparing field and value
     *
     * @var string
     */
    protected $_operator = '=';

    /**
     * Whether the value in this expression is a traversable
     *
     * @var bool
     */
    protected $_isMultiple = false;

    /**
     * A cached list of IExpression objects that were
     * found in the value for this expression.
     *
     * @var array<\Cake\Database\IExpression>
     */
    protected $_valueExpressions = [];

    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|string myField the field name to compare to a value
     * @param mixed myValue The value to be used in comparison
     * @param string|null myType the type name used to cast the value
     * @param string $operator the operator used for comparing field and value
     */
    this(myField, myValue, ?string myType = null, string $operator = '=') {
        this._type = myType;
        this.setField(myField);
        this.setValue(myValue);
        this._operator = $operator;
    }

    /**
     * Sets the value
     *
     * @param mixed myValue The value to compare
     * @return void
     */
    auto setValue(myValue): void
    {
        myValue = this._castToExpression(myValue, this._type);

        $isMultiple = this._type && strpos(this._type, '[]') !== false;
        if ($isMultiple) {
            [myValue, this._valueExpressions] = this._collectExpressions(myValue);
        }

        this._isMultiple = $isMultiple;
        this._value = myValue;
    }

    /**
     * Returns the value used for comparison
     *
     * @return mixed
     */
    auto getValue() {
        return this._value;
    }

    /**
     * Sets the operator to use for the comparison
     *
     * @param string $operator The operator to be used for the comparison.
     * @return void
     */
    auto setOperator(string $operator): void
    {
        this._operator = $operator;
    }

    /**
     * Returns the operator used for comparison
     *
     * @return string
     */
    auto getOperator(): string
    {
        return this._operator;
    }


    function sql(ValueBinder $binder): string
    {
        /** @var \Cake\Database\IExpression|string myField */
        myField = this._field;

        if (myField instanceof IExpression) {
            myField = myField.sql($binder);
        }

        if (this._value instanceof IdentifierExpression) {
            myTemplate = '%s %s %s';
            myValue = this._value.sql($binder);
        } elseif (this._value instanceof IExpression) {
            myTemplate = '%s %s (%s)';
            myValue = this._value.sql($binder);
        } else {
            [myTemplate, myValue] = this._stringExpression($binder);
        }

        return sprintf(myTemplate, myField, this._operator, myValue);
    }


    function traverse(Closure $callback) {
        if (this._field instanceof IExpression) {
            $callback(this._field);
            this._field.traverse($callback);
        }

        if (this._value instanceof IExpression) {
            $callback(this._value);
            this._value.traverse($callback);
        }

        foreach (this._valueExpressions as $v) {
            $callback($v);
            $v.traverse($callback);
        }

        return this;
    }

    /**
     * Create a deep clone.
     *
     * Clones the field and value if they are expression objects.
     *
     * @return void
     */
    auto __clone() {
        foreach (['_value', '_field'] as $prop) {
            if (this.{$prop} instanceof IExpression) {
                this.{$prop} = clone this.{$prop};
            }
        }
    }

    /**
     * Returns a template and a placeholder for the value after registering it
     * with the placeholder $binder
     *
     * @param \Cake\Database\ValueBinder $binder The value binder to use.
     * @return array First position containing the template and the second a placeholder
     */
    protected auto _stringExpression(ValueBinder $binder): array
    {
        myTemplate = '%s ';

        if (this._field instanceof IExpression && !this._field instanceof IdentifierExpression) {
            myTemplate = '(%s) ';
        }

        if (this._isMultiple) {
            myTemplate .= '%s (%s)';
            myType = this._type;
            if (myType !== null) {
                myType = str_replace('[]', '', myType);
            }
            myValue = this._flattenValue(this._value, $binder, myType);

            // To avoid SQL errors when comparing a field to a list of empty values,
            // better just throw an exception here
            if (myValue === '') {
                myField = this._field instanceof IExpression ? this._field.sql($binder) : this._field;
                /** @psalm-suppress PossiblyInvalidCast */
                throw new DatabaseException(
                    "Impossible to generate condition with empty list of values for field (myField)"
                );
            }
        } else {
            myTemplate .= '%s %s';
            myValue = this._bindValue(this._value, $binder, this._type);
        }

        return [myTemplate, myValue];
    }

    /**
     * Registers a value in the placeholder generator and returns the generated placeholder
     *
     * @param mixed myValue The value to bind
     * @param \Cake\Database\ValueBinder $binder The value binder to use
     * @param string|null myType The type of myValue
     * @return string generated placeholder
     */
    protected auto _bindValue(myValue, ValueBinder $binder, ?string myType = null): string
    {
        $placeholder = $binder.placeholder('c');
        $binder.bind($placeholder, myValue, myType);

        return $placeholder;
    }

    /**
     * Converts a traversable value into a set of placeholders generated by
     * $binder and separated by `,`
     *
     * @param iterable myValue the value to flatten
     * @param \Cake\Database\ValueBinder $binder The value binder to use
     * @param string|null myType the type to cast values to
     * @return string
     */
    protected auto _flattenValue(iterable myValue, ValueBinder $binder, ?string myType = null): string
    {
        $parts = [];
        if (is_array(myValue)) {
            foreach (this._valueExpressions as $k => $v) {
                $parts[$k] = $v.sql($binder);
                unset(myValue[$k]);
            }
        }

        if (!empty(myValue)) {
            $parts += $binder.generateManyNamed(myValue, myType);
        }

        return implode(',', $parts);
    }

    /**
     * Returns an array with the original myValues in the first position
     * and all IExpression objects that could be found in the second
     * position.
     *
     * @param \Cake\Database\IExpression|iterable myValues The rows to insert
     * @return array
     */
    protected auto _collectExpressions(myValues): array
    {
        if (myValues instanceof IExpression) {
            return [myValues, []];
        }

        $expressions = myResult = [];
        $isArray = is_array(myValues);

        if ($isArray) {
            /** @var array myResult */
            myResult = myValues;
        }

        foreach (myValues as $k => $v) {
            if ($v instanceof IExpression) {
                $expressions[$k] = $v;
            }

            if ($isArray) {
                myResult[$k] = $v;
            }
        }

        return [myResult, $expressions];
    }
}

// phpcs:disable
// Comparison will not load during instanceof checks so ensure it's loaded here
// @deprecated 4.1.0 Add backwards compatible alias.
class_alias('Cake\Database\Expression\ComparisonExpression', 'Cake\Database\Expression\Comparison');
// phpcs:enable
