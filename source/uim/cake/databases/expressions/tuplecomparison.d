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
     * @param uim.cake.databases.IExpression|array|string $fields the fields to use to form a tuple
     * @param uim.cake.databases.IExpression|array $values the values to use to form a tuple
     * @param array<string|null> $types the types names to use for casting each of the values, only
     * one type per position in the value array in needed
     * @param string $conjunction the operator used for comparing field and value
     */
    this($fields, $values, array $types = [], string $conjunction = "=") {
        _type = $types;
        this.setField($fields);
        _operator = $conjunction;
        this.setValue($values);
    }

    /**
     * Returns the type to be used for casting the value to a database representation
     *
     * @return array<string|null>
     */
    function getType(): array
    {
        return _type;
    }

    /**
     * Sets the value
     *
     * @param mixed $value The value to compare
     */
    void setValue($value) {
        if (this.isMulti()) {
            if (is_array($value) && !is_array(current($value))) {
                throw new InvalidArgumentException(
                    "Multi-tuple comparisons require a multi-tuple value, single-tuple given."
                );
            }
        } else {
            if (is_array($value) && is_array(current($value))) {
                throw new InvalidArgumentException(
                    "Single-tuple comparisons require a single-tuple value, multi-tuple given."
                );
            }
        }

        _value = $value;
    }


    string sql(ValueBinder aBinder) {
        $template = "(%s) %s (%s)";
        $fields = [];
        $originalFields = this.getField();

        if (!is_array($originalFields)) {
            $originalFields = [$originalFields];
        }

        foreach ($originalFields as $field) {
            $fields[] = $field instanceof IExpression ? $field.sql($binder) : $field;
        }

        $values = _stringifyValues($binder);

        $field = implode(", ", $fields);

        return sprintf($template, $field, _operator, $values);
    }

    /**
     * Returns a string with the values as placeholders in a string to be used
     * for the SQL version of this expression
     *
     * @param uim.cake.databases.ValueBinder aBinder The value binder to convert expressions with.
     */
    protected string _stringifyValues(ValueBinder aBinder) {
        $values = [];
        $parts = this.getValue();

        if ($parts instanceof IExpression) {
            return $parts.sql($binder);
        }

        foreach ($parts as $i: $value) {
            if ($value instanceof IExpression) {
                $values[] = $value.sql($binder);
                continue;
            }

            $type = _type;
            $isMultiOperation = this.isMulti();
            if (empty($type)) {
                $type = null;
            }

            if ($isMultiOperation) {
                $bound = [];
                foreach ($value as $k: $val) {
                    /** @var string $valType */
                    $valType = $type && isset($type[$k]) ? $type[$k] : $type;
                    $bound[] = _bindValue($val, $binder, $valType);
                }

                $values[] = sprintf("(%s)", implode(",", $bound));
                continue;
            }

            /** @var string $valType */
            $valType = $type && isset($type[$i]) ? $type[$i] : $type;
            $values[] = _bindValue($value, $binder, $valType);
        }

        return implode(", ", $values);
    }


    protected string _bindValue($value, ValueBinder aBinder, ?string $type = null) {
        $placeholder = $binder.placeholder("tuple");
        $binder.bind($placeholder, $value, $type);

        return $placeholder;
    }


    O traverse(this O)(Closure $callback) {
        /** @var array<string> $fields */
        $fields = this.getField();
        foreach ($fields as $field) {
            _traverseValue($field, $callback);
        }

        $value = this.getValue();
        if ($value instanceof IExpression) {
            $callback($value);
            $value.traverse($callback);

            return this;
        }

        foreach ($value as $val) {
            if (this.isMulti()) {
                foreach ($val as $v) {
                    _traverseValue($v, $callback);
                }
            } else {
                _traverseValue($val, $callback);
            }
        }

        return this;
    }

    /**
     * Conditionally executes the callback for the passed value if
     * it is an IExpression
     *
     * @param mixed $value The value to traverse
     * @param \Closure $callback The callable to use when traversing
     */
    protected void _traverseValue($value, Closure $callback) {
        if ($value instanceof IExpression) {
            $callback($value);
            $value.traverse($callback);
        }
    }

    /**
     * Determines if each of the values in this expressions is a tuple in
     * itself
     */
    bool isMulti()
    {
        return in_array(strtolower(_operator), ["in", "not in"]);
    }
}
