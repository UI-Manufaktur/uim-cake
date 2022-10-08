module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use Closure;
use InvalidArgumentException;

/**
 * This expression represents SQL fragments that are used for comparing one tuple
 * to another, one tuple to a set of other tuples or one tuple to an expression
 */
class TupleComparison : ComparisonExpression
{
    /**
     * The type to be used for casting the value to a database representation
     *
     * @var array<string|null>
     * @psalm-suppress NonInvariantDocblockPropertyType
     */
    protected $_type;

    /**
     * Constructor
     *
     * @param \Cake\Database\IExpression|array|string myFields the fields to use to form a tuple
     * @param \Cake\Database\IExpression|array myValues the values to use to form a tuple
     * @param array<string|null> myTypes the types names to use for casting each of the values, only
     * one type per position in the value array in needed
     * @param string $conjunction the operator used for comparing field and value
     */
    this(myFields, myValues, array myTypes = [], string $conjunction = '=')
    {
        this._type = myTypes;
        this.setField(myFields);
        this._operator = $conjunction;
        this.setValue(myValues);
    }

    /**
     * Returns the type to be used for casting the value to a database representation
     *
     * @return array<string|null>
     */
    auto getType(): array
    {
        return this._type;
    }

    /**
     * Sets the value
     *
     * @param mixed myValue The value to compare
     * @return void
     */
    auto setValue(myValue): void
    {
        if (this.isMulti()) {
            if (is_array(myValue) && !is_array(current(myValue))) {
                throw new InvalidArgumentException(
                    'Multi-tuple comparisons require a multi-tuple value, single-tuple given.'
                );
            }
        } else {
            if (is_array(myValue) && is_array(current(myValue))) {
                throw new InvalidArgumentException(
                    'Single-tuple comparisons require a single-tuple value, multi-tuple given.'
                );
            }
        }

        this._value = myValue;
    }


    function sql(ValueBinder $binder): string
    {
        myTemplate = '(%s) %s (%s)';
        myFields = [];
        $originalFields = this.getField();

        if (!is_array($originalFields)) {
            $originalFields = [$originalFields];
        }

        foreach ($originalFields as myField) {
            myFields[] = myField instanceof IExpression ? myField.sql($binder) : myField;
        }

        myValues = this._stringifyValues($binder);

        myField = implode(', ', myFields);

        return sprintf(myTemplate, myField, this._operator, myValues);
    }

    /**
     * Returns a string with the values as placeholders in a string to be used
     * for the SQL version of this expression
     *
     * @param \Cake\Database\ValueBinder $binder The value binder to convert expressions with.
     * @return string
     */
    protected auto _stringifyValues(ValueBinder $binder): string
    {
        myValues = [];
        $parts = this.getValue();

        if ($parts instanceof IExpression) {
            return $parts.sql($binder);
        }

        foreach ($parts as $i => myValue) {
            if (myValue instanceof IExpression) {
                myValues[] = myValue.sql($binder);
                continue;
            }

            myType = this._type;
            $isMultiOperation = this.isMulti();
            if (empty(myType)) {
                myType = null;
            }

            if ($isMultiOperation) {
                $bound = [];
                foreach (myValue as $k => $val) {
                    /** @var string $valType */
                    $valType = myType && isset(myType[$k]) ? myType[$k] : myType;
                    $bound[] = this._bindValue($val, $binder, $valType);
                }

                myValues[] = sprintf('(%s)', implode(',', $bound));
                continue;
            }

            /** @var string $valType */
            $valType = myType && isset(myType[$i]) ? myType[$i] : myType;
            myValues[] = this._bindValue(myValue, $binder, $valType);
        }

        return implode(', ', myValues);
    }


    protected auto _bindValue(myValue, ValueBinder $binder, ?string myType = null): string
    {
        $placeholder = $binder.placeholder('tuple');
        $binder.bind($placeholder, myValue, myType);

        return $placeholder;
    }


    function traverse(Closure $callback)
    {
        /** @var array<string> myFields */
        myFields = this.getField();
        foreach (myFields as myField) {
            this._traverseValue(myField, $callback);
        }

        myValue = this.getValue();
        if (myValue instanceof IExpression) {
            $callback(myValue);
            myValue.traverse($callback);

            return this;
        }

        foreach (myValue as $val) {
            if (this.isMulti()) {
                foreach ($val as $v) {
                    this._traverseValue($v, $callback);
                }
            } else {
                this._traverseValue($val, $callback);
            }
        }

        return this;
    }

    /**
     * Conditionally executes the callback for the passed value if
     * it is an IExpression
     *
     * @param mixed myValue The value to traverse
     * @param \Closure $callback The callable to use when traversing
     * @return void
     */
    protected auto _traverseValue(myValue, Closure $callback): void
    {
        if (myValue instanceof IExpression) {
            $callback(myValue);
            myValue.traverse($callback);
        }
    }

    /**
     * Determines if each of the values in this expressions is a tuple in
     * itself
    bool isMulti()
    {
        return in_array(strtolower(this._operator), ['in', 'not in']);
    }
}
