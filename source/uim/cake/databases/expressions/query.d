module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.TypeMapTrait;
import uim.cake.databases.ValueBinder;
use Closure;
use Countable;
use InvalidArgumentException;

/**
 * Represents a SQL Query expression. Internally it stores a tree of
 * expressions that can be compiled by converting this object to string
 * and will contain a correctly parenthesized and nested expression.
 */
class QueryExpression : IExpression, Countable
{
    use TypeMapTrait;

    /**
     * String to be used for joining each of the internal expressions
     * this object internally stores for example "AND", "OR", etc.
     */
    protected string $_conjunction;

    /**
     * A list of strings or other expression objects that represent the "branches" of
     * the expression tree. For example one key of the array might look like "sum > :value"
     *
     * @var array
     */
    protected $_conditions = [];

    /**
     * Constructor. A new expression object can be created without any params and
     * be built dynamically. Otherwise, it is possible to pass an array of conditions
     * containing either a tree-like array structure to be parsed and/or other
     * expression objects. Optionally, you can set the conjunction keyword to be used
     * for joining each part of this level of the expression tree.
     *
     * @param uim.cake.databases.IExpression|array|string $conditions Tree like array structure
     * containing all the conditions to be added or nested inside this expression object.
     * @param uim.cake.databases.TypeMap|array $types Associative array of types to be associated with the values
     * passed in $conditions.
     * @param string $conjunction the glue that will join all the string conditions at this
     * level of the expression tree. For example "AND", "OR", "XOR"...
     * @see uim.cake.databases.Expression\QueryExpression::add() for more details on $conditions and $types
     */
    this($conditions = [], $types = [], $conjunction = "AND") {
        this.setTypeMap($types);
        this.setConjunction(strtoupper($conjunction));
        if (!empty($conditions)) {
            this.add($conditions, this.getTypeMap().getTypes());
        }
    }

    /**
     * Changes the conjunction for the conditions at this level of the expression tree.
     *
     * @param string $conjunction Value to be used for joining conditions
     * @return this
     */
    function setConjunction(string $conjunction) {
        _conjunction = strtoupper($conjunction);

        return this;
    }

    /**
     * Gets the currently configured conjunction for the conditions at this level of the expression tree.
     */
    string getConjunction() {
        return _conjunction;
    }

    /**
     * Adds one or more conditions to this expression object. Conditions can be
     * expressed in a one dimensional array, that will cause all conditions to
     * be added directly at this level of the tree or they can be nested arbitrarily
     * making it create more expression objects that will be nested inside and
     * configured to use the specified conjunction.
     *
     * If the type passed for any of the fields is expressed "type[]" (note braces)
     * then it will cause the placeholder to be re-written dynamically so if the
     * value is an array, it will create as many placeholders as values are in it.
     *
     * @param uim.cake.databases.IExpression|array|string $conditions single or multiple conditions to
     * be added. When using an array and the key is "OR" or "AND" a new expression
     * object will be created with that conjunction and internal array value passed
     * as conditions.
     * @param array<int|string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @see uim.cake.databases.Query::where() for examples on conditions
     * @return this
     */
    function add($conditions, array $types = []) {
        if (is_string($conditions)) {
            _conditions[] = $conditions;

            return this;
        }

        if ($conditions instanceof IExpression) {
            _conditions[] = $conditions;

            return this;
        }

        _addConditions($conditions, $types);

        return this;
    }

    /**
     * Adds a new condition to the expression object in the form "field = value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * If it is suffixed with "[]" and the value is an array then multiple placeholders
     * will be created, one per each value in the array.
     * @return this
     */
    function eq($field, $value, ?string $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "="));
    }

    /**
     * Adds a new condition to the expression object in the form "field != value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * If it is suffixed with "[]" and the value is an array then multiple placeholders
     * will be created, one per each value in the array.
     * @return this
     */
    function notEq($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "!="));
    }

    /**
     * Adds a new condition to the expression object in the form "field > value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function gt($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, ">"));
    }

    /**
     * Adds a new condition to the expression object in the form "field < value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function lt($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "<"));
    }

    /**
     * Adds a new condition to the expression object in the form "field >= value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function gte($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, ">="));
    }

    /**
     * Adds a new condition to the expression object in the form "field <= value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function lte($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "<="));
    }

    /**
     * Adds a new condition to the expression object in the form "field IS NULL".
     *
     * @param uim.cake.databases.IExpression|string $field database field to be
     * tested for null
     * @return this
     */
    bool isNull($field) {
        if (!($field instanceof IExpression)) {
            $field = new IdentifierExpression($field);
        }

        return this.add(new UnaryExpression("IS NULL", $field, UnaryExpression::POSTFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "field IS NOT NULL".
     *
     * @param uim.cake.databases.IExpression|string $field database field to be
     * tested for not null
     * @return this
     */
    bool isNotNull($field) {
        if (!($field instanceof IExpression)) {
            $field = new IdentifierExpression($field);
        }

        return this.add(new UnaryExpression("IS NOT NULL", $field, UnaryExpression::POSTFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "field LIKE value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function like($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "LIKE"));
    }

    /**
     * Adds a new condition to the expression object in the form "field NOT LIKE value".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param mixed $value The value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function notLike($field, $value, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new ComparisonExpression($field, $value, $type, "NOT LIKE"));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field IN (value1, value2)".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param uim.cake.databases.IExpression|array|string $values the value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function in($field, $values, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }
        $type = $type ?: "string";
        $type .= "[]";
        $values = $values instanceof IExpression ? $values : (array)$values;

        return this.add(new ComparisonExpression($field, $values, $type, "IN"));
    }

    /**
     * Adds a new case expression to the expression object
     *
     * @param uim.cake.databases.IExpression|array $conditions The conditions to test. Must be a IExpression
     * instance, or an array of IExpression instances.
     * @param uim.cake.databases.IExpression|array $values Associative array of values to be associated with the
     * conditions passed in $conditions. If there are more $values than $conditions,
     * the last $value is used as the `ELSE` value.
     * @param array<string> $types Associative array of types to be associated with the values
     * passed in $values
     * @return this
     * @deprecated 4.3.0 Use QueryExpression::case() or CaseStatementExpression instead
     */
    function addCase($conditions, $values = [], $types = []) {
        deprecationWarning("QueryExpression::addCase() is deprecated, use case() instead.");

        return this.add(new CaseExpression($conditions, $values, $types));
    }

    /**
     * Returns a new case expression object.
     *
     * When a value is set, the syntax generated is
     * `CASE case_value WHEN when_value ... END` (simple case),
     * where the `when_value`"s are compared against the
     * `case_value`.
     *
     * When no value is set, the syntax generated is
     * `CASE WHEN when_conditions ... END` (searched case),
     * where the conditions hold the comparisons.
     *
     * Note that `null` is a valid case value, and thus should
     * only be passed if you actually want to create the simple
     * case expression variant!
     *
     * @param uim.cake.databases.IExpression|object|scalar|null $value The case value.
     * @param string|null $type The case value type. If no type is provided, the type will be tried to be inferred
     *  from the value.
     * @return uim.cake.databases.Expression\CaseStatementExpression
     */
    function case($value = null, ?string $type = null): CaseStatementExpression
    {
        if (func_num_args() > 0) {
            $expression = new CaseStatementExpression($value, $type);
        } else {
            $expression = new CaseStatementExpression();
        }

        return $expression.setTypeMap(this.getTypeMap());
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field NOT IN (value1, value2)".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param uim.cake.databases.IExpression|array|string $values the value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function notIn($field, $values, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }
        $type = $type ?: "string";
        $type .= "[]";
        $values = $values instanceof IExpression ? $values : (array)$values;

        return this.add(new ComparisonExpression($field, $values, $type, "NOT IN"));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "(field NOT IN (value1, value2) OR field IS NULL".
     *
     * @param uim.cake.databases.IExpression|string $field Database field to be compared against value
     * @param uim.cake.databases.IExpression|array|string $values the value to be bound to $field for comparison
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function notInOrNull($field, $values, ?string $type = null) {
        $or = new static([], [], "OR");
        $or
            .notIn($field, $values, $type)
            .isNull($field);

        return this.add($or);
    }

    /**
     * Adds a new condition to the expression object in the form "EXISTS (...)".
     *
     * @param uim.cake.databases.IExpression $expression the inner query
     * @return this
     */
    function exists(IExpression $expression) {
        return this.add(new UnaryExpression("EXISTS", $expression, UnaryExpression::PREFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "NOT EXISTS (...)".
     *
     * @param uim.cake.databases.IExpression $expression the inner query
     * @return this
     */
    function notExists(IExpression $expression) {
        return this.add(new UnaryExpression("NOT EXISTS", $expression, UnaryExpression::PREFIX));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field BETWEEN from AND to".
     *
     * @param uim.cake.databases.IExpression|string $field The field name to compare for values inbetween the range.
     * @param mixed $from The initial value of the range.
     * @param mixed $to The ending value in the comparison range.
     * @param string|null $type the type name for $value as configured using the Type map.
     * @return this
     */
    function between($field, $from, $to, $type = null) {
        if ($type == null) {
            $type = _calculateType($field);
        }

        return this.add(new BetweenExpression($field, $from, $to, $type));
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "AND"
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions to be joined with AND
     * @param array<string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return uim.cake.databases.Expression\QueryExpression
     */
    function and($conditions, $types = []) {
        if ($conditions instanceof Closure) {
            return $conditions(new static([], this.getTypeMap().setTypes($types)));
        }

        return new static($conditions, this.getTypeMap().setTypes($types));
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "OR"
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions to be joined with OR
     * @param array<string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return uim.cake.databases.Expression\QueryExpression
     */
    function or($conditions, $types = []) {
        if ($conditions instanceof Closure) {
            return $conditions(new static([], this.getTypeMap().setTypes($types), "OR"));
        }

        return new static($conditions, this.getTypeMap().setTypes($types), "OR");
    }

    // phpcs:disable PSR1.Methods.CamelCapsMethodName.NotCamelCaps

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "AND"
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions to be joined with AND
     * @param array<string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return uim.cake.databases.Expression\QueryExpression
     * @deprecated 4.0.0 Use {@link and()} instead.
     */
    function and_($conditions, $types = []) {
        deprecationWarning("QueryExpression::and_() is deprecated use and() instead.");

        return this.and($conditions, $types);
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "OR"
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions to be joined with OR
     * @param array<string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return uim.cake.databases.Expression\QueryExpression
     * @deprecated 4.0.0 Use {@link or()} instead.
     */
    function or_($conditions, $types = []) {
        deprecationWarning("QueryExpression::or_() is deprecated use or() instead.");

        return this.or($conditions, $types);
    }

    // phpcs:enable

    /**
     * Adds a new set of conditions to this level of the tree and negates
     * the final result by prepending a NOT, it will look like
     * "NOT ( (condition1) AND (conditions2) )" conjunction depends on the one
     * currently configured for this object.
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions to be added and negated
     * @param array<string, string> $types Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return this
     */
    function not($conditions, $types = []) {
        return this.add(["NOT": $conditions], $types);
    }

    /**
     * Returns the number of internal conditions that are stored in this expression.
     * Useful to determine if this expression object is void or it will generate
     * a non-empty string when compiled
     */
    size_t count()
    {
        return count(_conditions);
    }

    /**
     * Builds equal condition or assignment with identifier wrapping.
     *
     * @param string $leftField Left join condition field name.
     * @param string $rightField Right join condition field name.
     * @return this
     */
    function equalFields(string $leftField, string $rightField) {
        $wrapIdentifier = function ($field) {
            if ($field instanceof IExpression) {
                return $field;
            }

            return new IdentifierExpression($field);
        };

        return this.eq($wrapIdentifier($leftField), $wrapIdentifier($rightField));
    }


    string sql(ValueBinder aBinder) {
        $len = this.count();
        if ($len == 0) {
            return "";
        }
        $conjunction = _conjunction;
        $template = $len == 1 ? "%s" : "(%s)";
        $parts = [];
        foreach (_conditions as $part) {
            if ($part instanceof Query) {
                $part = "(" ~ $part.sql($binder) ~ ")";
            } elseif ($part instanceof IExpression) {
                $part = $part.sql($binder);
            }
            if ($part != "") {
                $parts[] = $part;
            }
        }

        return sprintf($template, implode(" $conjunction ", $parts));
    }


    O traverse(this O)(Closure $callback) {
        foreach (_conditions as $c) {
            if ($c instanceof IExpression) {
                $callback($c);
                $c.traverse($callback);
            }
        }

        return this;
    }

    /**
     * Executes a callable function for each of the parts that form this expression.
     *
     * The callable bool is required to return a value with which the currently
     * visited part will be replaced. If the callable function returns null then
     * the part will be discarded completely from this expression.
     *
     * The callback function will receive each of the conditions as first param and
     * the key as second param. It is possible to declare the second parameter as
     * passed by reference, this will enable you to change the key under which the
     * modified part is stored.
     *
     * @param callable $callback The callable to apply to each part.
     * @return this
     */
    function iterateParts(callable $callback) {
        $parts = [];
        foreach (_conditions as $k: $c) {
            $key = &$k;
            $part = $callback($c, $key);
            if ($part != null) {
                $parts[$key] = $part;
            }
        }
        _conditions = $parts;

        return this;
    }

    /**
     * Check whether a callable is acceptable.
     *
     * We don"t accept ["class", "method"] style callbacks,
     * as they often contain user input and arrays of strings
     * are easy to sneak in.
     *
     * @param uim.cake.databases.IExpression|callable|array|string $callable The callable to check.
     * @return bool Valid callable.
     * @deprecated 4.2.0 This method is unused.
     * @codeCoverageIgnore
     */
    bool isCallable($callable) {
        if (is_string($callable)) {
            return false;
        }
        if (is_object($callable) && is_callable($callable)) {
            return true;
        }

        return is_array($callable) && isset($callable[0]) && is_object($callable[0]) && is_callable($callable);
    }

    /**
     * Returns true if this expression contains any other nested
     * IExpression objects
     */
    bool hasNestedExpression() {
        foreach (_conditions as $c) {
            if ($c instanceof IExpression) {
                return true;
            }
        }

        return false;
    }

    /**
     * Auxiliary function used for decomposing a nested array of conditions and build
     * a tree structure inside this object to represent the full SQL expression.
     * String conditions are stored directly in the conditions, while any other
     * representation is wrapped around an adequate instance or of this class.
     *
     * @param array $conditions list of conditions to be stored in this object
     * @param array<int|string, string> $types list of types associated on fields referenced in $conditions
     */
    protected void _addConditions(array $conditions, array $types) {
        $operators = ["and", "or", "xor"];

        $typeMap = this.getTypeMap().setTypes($types);

        foreach ($conditions as $k: $c) {
            $numericKey = is_numeric($k);

            if ($c instanceof Closure) {
                $expr = new static([], $typeMap);
                $c = $c($expr, this);
            }

            if ($numericKey && empty($c)) {
                continue;
            }

            $isArray = is_array($c);
            $isOperator = $isNot = false;
            if (!$numericKey) {
                $normalizedKey = strtolower($k);
                $isOperator = in_array($normalizedKey, $operators);
                $isNot = $normalizedKey == "not";
            }

            if (($isOperator || $isNot) && ($isArray || $c instanceof Countable) && count($c) == 0) {
                continue;
            }

            if ($numericKey && $c instanceof IExpression) {
                _conditions[] = $c;
                continue;
            }

            if ($numericKey && is_string($c)) {
                _conditions[] = $c;
                continue;
            }

            if ($numericKey && $isArray || $isOperator) {
                _conditions[] = new static($c, $typeMap, $numericKey ? "AND" : $k);
                continue;
            }

            if ($isNot) {
                _conditions[] = new UnaryExpression("NOT", new static($c, $typeMap));
                continue;
            }

            if (!$numericKey) {
                _conditions[] = _parseCondition($k, $c);
            }
        }
    }

    /**
     * Parses a string conditions by trying to extract the operator inside it if any
     * and finally returning either an adequate QueryExpression object or a plain
     * string representation of the condition. This bool is responsible for
     * generating the placeholders and replacing the values by them, while storing
     * the value elsewhere for future binding.
     *
     * @param string $field The value from which the actual field and operator will
     * be extracted.
     * @param mixed $value The value to be bound to a placeholder for the field
     * @return uim.cake.databases.IExpression
     * @throws \InvalidArgumentException If operator is invalid or missing on NULL usage.
     */
    protected function _parseCondition(string $field, $value) {
        $field = trim($field);
        $operator = "=";
        $expression = $field;

        $spaces = substr_count($field, " ");
        // Handle field values that contain multiple spaces, such as
        // operators with a space in them like `field IS NOT` and
        // `field NOT LIKE`, or combinations with function expressions
        // like `CONCAT(first_name, " ", last_name) IN`.
        if ($spaces > 1) {
            $parts = explode(" ", $field);
            if (preg_match("/(is not|not \w+)$/i", $field)) {
                $last = array_pop($parts);
                $second = array_pop($parts);
                $parts[] = "{$second} {$last}";
            }
            $operator = array_pop($parts);
            $expression = implode(" ", $parts);
        } elseif ($spaces == 1) {
            $parts = explode(" ", $field, 2);
            [$expression, $operator] = $parts;
        }
        $operator = strtolower(trim($operator));
        $type = this.getTypeMap().type($expression);

        $typeMultiple = (is_string($type) && strpos($type, "[]") != false);
        if (in_array($operator, ["in", "not in"]) || $typeMultiple) {
            $type = $type ?: "string";
            if (!$typeMultiple) {
                $type .= "[]";
            }
            $operator = $operator == "=" ? "IN" : $operator;
            $operator = $operator == "!=" ? "NOT IN" : $operator;
            $typeMultiple = true;
        }

        if ($typeMultiple) {
            $value = $value instanceof IExpression ? $value : (array)$value;
        }

        if ($operator == "is" && $value == null) {
            return new UnaryExpression(
                "IS NULL",
                new IdentifierExpression($expression),
                UnaryExpression::POSTFIX
            );
        }

        if ($operator == "is not" && $value == null) {
            return new UnaryExpression(
                "IS NOT NULL",
                new IdentifierExpression($expression),
                UnaryExpression::POSTFIX
            );
        }

        if ($operator == "is" && $value != null) {
            $operator = "=";
        }

        if ($operator == "is not" && $value != null) {
            $operator = "!=";
        }

        if ($value == null && _conjunction != ",") {
            throw new InvalidArgumentException(
                sprintf("Expression `%s` is missing operator (IS, IS NOT) with `null` value.", $expression)
            );
        }

        return new ComparisonExpression($expression, $value, $type, $operator);
    }

    /**
     * Returns the type name for the passed field if it was stored in the typeMap
     *
     * @param uim.cake.databases.IExpression|string $field The field name to get a type for.
     * @return string|null The computed type or null, if the type is unknown.
     */
    protected Nullable!string _calculateType($field)
    {
        $field = $field instanceof IdentifierExpression ? $field.getIdentifier() : $field;
        if (is_string($field)) {
            return this.getTypeMap().type($field);
        }

        return null;
    }

    /**
     * Clone this object and its subtree of expressions.
     */
    void __clone() {
        foreach (_conditions as $i: $condition) {
            if ($condition instanceof IExpression) {
                _conditions[$i] = clone $condition;
            }
        }
    }
}
