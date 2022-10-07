module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.Type\ExpressionTypeCasterTrait;
import uim.cake.database.ValueBinder;
use Closure;

/**
 * This class represents a SQL Case statement
 *
 * @deprecated 4.3.0 Use QueryExpression::case() or CaseStatementExpression instead
 */
class CaseExpression : IExpression
{
    use ExpressionTypeCasterTrait;

    /**
     * A list of strings or other expression objects that represent the conditions of
     * the case statement. For example one key of the array might look like "sum > :value"
     *
     * @var array
     */
    protected $_conditions = [];

    /**
     * Values that are associated with the conditions in the $_conditions array.
     * Each value represents the 'true' value for the condition with the corresponding key.
     *
     * @var array
     */
    protected $_values = [];

    /**
     * The `ELSE` value for the case statement. If null then no `ELSE` will be included.
     *
     * @var \Cake\Database\IExpression|array|string|null
     */
    protected $_elseValue;

    /**
     * Constructs the case expression
     *
     * @param \Cake\Database\IExpression|array $conditions The conditions to test. Must be a IExpression
     * instance, or an array of IExpression instances.
     * @param \Cake\Database\IExpression|array myValues Associative array of values to be associated with the
     * conditions passed in $conditions. If there are more myValues than $conditions,
     * the last myValue is used as the `ELSE` value.
     * @param array<string> myTypes Associative array of types to be associated with the values
     * passed in myValues
     */
    this($conditions = [], myValues = [], myTypes = [])
    {
        $conditions = is_array($conditions) ? $conditions : [$conditions];
        myValues = is_array(myValues) ? myValues : [myValues];
        myTypes = is_array(myTypes) ? myTypes : [myTypes];

        if (!empty($conditions)) {
            this.add($conditions, myValues, myTypes);
        }

        if (count(myValues) > count($conditions)) {
            end(myValues);
            myKey = key(myValues);
            this.elseValue(myValues[myKey], myTypes[myKey] ?? null);
        }
    }

    /**
     * Adds one or more conditions and their respective true values to the case object.
     * Conditions must be a one dimensional array or a QueryExpression.
     * The trueValues must be a similar structure, but may contain a string value.
     *
     * @param \Cake\Database\IExpression|array $conditions Must be a IExpression instance,
     *   or an array of IExpression instances.
     * @param \Cake\Database\IExpression|array myValues Associative array of values of each condition
     * @param array<string> myTypes Associative array of types to be associated with the values
     * @return this
     */
    function add($conditions = [], myValues = [], myTypes = [])
    {
        $conditions = is_array($conditions) ? $conditions : [$conditions];
        myValues = is_array(myValues) ? myValues : [myValues];
        myTypes = is_array(myTypes) ? myTypes : [myTypes];

        this._addExpressions($conditions, myValues, myTypes);

        return this;
    }

    /**
     * Iterates over the passed in conditions and ensures that there is a matching true value for each.
     * If no matching true value, then it is defaulted to '1'.
     *
     * @param array $conditions Array of IExpression instances.
     * @param array<mixed> myValues Associative array of values of each condition
     * @param array<string> myTypes Associative array of types to be associated with the values
     * @return void
     */
    protected auto _addExpressions(array $conditions, array myValues, array myTypes): void
    {
        $rawValues = array_values(myValues);
        myKeyValues = array_keys(myValues);

        foreach ($conditions as $k => $c) {
            $numericKey = is_numeric($k);

            if ($numericKey && empty($c)) {
                continue;
            }

            if (!$c instanceof IExpression) {
                continue;
            }

            this._conditions[] = $c;
            myValue = $rawValues[$k] ?? 1;

            if (myValue === 'literal') {
                myValue = myKeyValues[$k];
                this._values[] = myValue;
                continue;
            }

            if (myValue === 'identifier') {
                /** @var string myIdentifier */
                myIdentifier = myKeyValues[$k];
                myValue = new IdentifierExpression(myIdentifier);
                this._values[] = myValue;
                continue;
            }

            myType = myTypes[$k] ?? null;

            if (myType !== null && !myValue instanceof IExpression) {
                myValue = this._castToExpression(myValue, myType);
            }

            if (myValue instanceof IExpression) {
                this._values[] = myValue;
                continue;
            }

            this._values[] = ['value' => myValue, 'type' => myType];
        }
    }

    /**
     * Sets the default value
     *
     * @param \Cake\Database\IExpression|array|string|null myValue Value to set
     * @param string|null myType Type of value
     * @return void
     */
    function elseValue(myValue = null, ?string myType = null): void
    {
        if (is_array(myValue)) {
            end(myValue);
            myValue = key(myValue);
        }

        if (myValue !== null && !myValue instanceof IExpression) {
            myValue = this._castToExpression(myValue, myType);
        }

        if (!myValue instanceof IExpression) {
            myValue = ['value' => myValue, 'type' => myType];
        }

        this._elseValue = myValue;
    }

    /**
     * Compiles the relevant parts into sql
     *
     * @param \Cake\Database\IExpression|array|string $part The part to compile
     * @param \Cake\Database\ValueBinder $binder Sql generator
     * @return string
     */
    protected auto _compile($part, ValueBinder $binder): string
    {
        if ($part instanceof IExpression) {
            $part = $part.sql($binder);
        } elseif (is_array($part)) {
            $placeholder = $binder.placeholder('param');
            $binder.bind($placeholder, $part['value'], $part['type']);
            $part = $placeholder;
        }

        return $part;
    }

    /**
     * Converts the Node into a SQL string fragment.
     *
     * @param \Cake\Database\ValueBinder $binder Placeholder generator object
     * @return string
     */
    function sql(ValueBinder $binder): string
    {
        $parts = [];
        $parts[] = 'CASE';
        foreach (this._conditions as $k => $part) {
            myValue = this._values[$k];
            $parts[] = 'WHEN ' . this._compile($part, $binder) . ' THEN ' . this._compile(myValue, $binder);
        }
        if (this._elseValue !== null) {
            $parts[] = 'ELSE';
            $parts[] = this._compile(this._elseValue, $binder);
        }
        $parts[] = 'END';

        return implode(' ', $parts);
    }


    function traverse(Closure $callback)
    {
        foreach (['_conditions', '_values'] as $part) {
            foreach (this.{$part} as $c) {
                if ($c instanceof IExpression) {
                    $callback($c);
                    $c.traverse($callback);
                }
            }
        }
        if (this._elseValue instanceof IExpression) {
            $callback(this._elseValue);
            this._elseValue.traverse($callback);
        }

        return this;
    }
}
