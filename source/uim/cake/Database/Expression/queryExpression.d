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
     *
     * @var string
     */
    protected $_conjunction;

    /**
     * A list of strings or other expression objects that represent the "branches" of
     * the expression tree. For example one key of the array might look like "sum > :value"
     *
     * @var array
     */
    protected $_conditions = [];

    /**
     * Constructor. A new expression object can be created without any params and
     * be built dynamically. Otherwise it is possible to pass an array of conditions
     * containing either a tree-like array structure to be parsed and/or other
     * expression objects. Optionally, you can set the conjunction keyword to be used
     * for joining each part of this level of the expression tree.
     *
     * @param \Cake\Database\IExpression|array|string $conditions Tree like array structure
     * containing all the conditions to be added or nested inside this expression object.
     * @param \Cake\Database\TypeMap|array myTypes Associative array of types to be associated with the values
     * passed in $conditions.
     * @param string $conjunction the glue that will join all the string conditions at this
     * level of the expression tree. For example "AND", "OR", "XOR"...
     * @see \Cake\Database\Expression\QueryExpression::add() for more details on $conditions and myTypes
     */
    this($conditions = [], myTypes = [], $conjunction = 'AND') {
        this.setTypeMap(myTypes);
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
    auto setConjunction(string $conjunction) {
        this._conjunction = strtoupper($conjunction);

        return this;
    }

    /**
     * Gets the currently configured conjunction for the conditions at this level of the expression tree.
     *
     * @return string
     */
    auto getConjunction(): string
    {
        return this._conjunction;
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
     * @param \Cake\Database\IExpression|array|string $conditions single or multiple conditions to
     * be added. When using an array and the key is 'OR' or 'AND' a new expression
     * object will be created with that conjunction and internal array value passed
     * as conditions.
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @see \Cake\Database\Query::where() for examples on conditions
     * @return this
     */
    function add($conditions, array myTypes = []) {
        if (is_string($conditions)) {
            this._conditions[] = $conditions;

            return this;
        }

        if ($conditions instanceof IExpression) {
            this._conditions[] = $conditions;

            return this;
        }

        this._addConditions($conditions, myTypes);

        return this;
    }

    /**
     * Adds a new condition to the expression object in the form "field = value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * If it is suffixed with "[]" and the value is an array then multiple placeholders
     * will be created, one per each value in the array.
     * @return this
     */
    function eq(myField, myValue, ?string myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '='));
    }

    /**
     * Adds a new condition to the expression object in the form "field != value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * If it is suffixed with "[]" and the value is an array then multiple placeholders
     * will be created, one per each value in the array.
     * @return this
     */
    function notEq(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '!='));
    }

    /**
     * Adds a new condition to the expression object in the form "field > value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function gt(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '>'));
    }

    /**
     * Adds a new condition to the expression object in the form "field < value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function lt(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '<'));
    }

    /**
     * Adds a new condition to the expression object in the form "field >= value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function gte(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '>='));
    }

    /**
     * Adds a new condition to the expression object in the form "field <= value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function lte(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, '<='));
    }

    /**
     * Adds a new condition to the expression object in the form "field IS NULL".
     *
     * @param \Cake\Database\IExpression|string myField database field to be
     * tested for null
     * @return this
     */
    function isNull(myField) {
        if (!(myField instanceof IExpression)) {
            myField = new IdentifierExpression(myField);
        }

        return this.add(new UnaryExpression('IS NULL', myField, UnaryExpression::POSTFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "field IS NOT NULL".
     *
     * @param \Cake\Database\IExpression|string myField database field to be
     * tested for not null
     * @return this
     */
    function isNotNull(myField) {
        if (!(myField instanceof IExpression)) {
            myField = new IdentifierExpression(myField);
        }

        return this.add(new UnaryExpression('IS NOT NULL', myField, UnaryExpression::POSTFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "field LIKE value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function like(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, 'LIKE'));
    }

    /**
     * Adds a new condition to the expression object in the form "field NOT LIKE value".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param mixed myValue The value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function notLike(myField, myValue, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new ComparisonExpression(myField, myValue, myType, 'NOT LIKE'));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field IN (value1, value2)".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param \Cake\Database\IExpression|array|string myValues the value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function in(myField, myValues, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }
        myType = myType ?: 'string';
        myType .= '[]';
        myValues = myValues instanceof IExpression ? myValues : (array)myValues;

        return this.add(new ComparisonExpression(myField, myValues, myType, 'IN'));
    }

    /**
     * Adds a new case expression to the expression object
     *
     * @param \Cake\Database\IExpression|array $conditions The conditions to test. Must be a IExpression
     * instance, or an array of IExpression instances.
     * @param \Cake\Database\IExpression|array myValues Associative array of values to be associated with the
     * conditions passed in $conditions. If there are more myValues than $conditions,
     * the last myValue is used as the `ELSE` value.
     * @param array<string> myTypes Associative array of types to be associated with the values
     * passed in myValues
     * @return this
     * @deprecated 4.3.0 Use QueryExpression::case() or CaseStatementExpression instead
     */
    function addCase($conditions, myValues = [], myTypes = []) {
        deprecationWarning('QueryExpression::addCase() is deprecated, use case() instead.');

        return this.add(new CaseExpression($conditions, myValues, myTypes));
    }

    /**
     * Returns a new case expression object.
     *
     * When a value is set, the syntax generated is
     * `CASE case_value WHEN when_value ... END` (simple case),
     * where the `when_value`'s are compared against the
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
     * @param \Cake\Database\IExpression|object|scalar|null myValue The case value.
     * @param string|null myType The case value type. If no type is provided, the type will be tried to be inferred
     *  from the value.
     * @return \Cake\Database\Expression\CaseStatementExpression
     */
    function case(myValue = null, ?string myType = null): CaseStatementExpression
    {
        if (func_num_args() > 0) {
            $expression = new CaseStatementExpression(myValue, myType);
        } else {
            $expression = new CaseStatementExpression();
        }

        return $expression.setTypeMap(this.getTypeMap());
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field NOT IN (value1, value2)".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param \Cake\Database\IExpression|array|string myValues the value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function notIn(myField, myValues, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }
        myType = myType ?: 'string';
        myType .= '[]';
        myValues = myValues instanceof IExpression ? myValues : (array)myValues;

        return this.add(new ComparisonExpression(myField, myValues, myType, 'NOT IN'));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "(field NOT IN (value1, value2) OR field IS NULL".
     *
     * @param \Cake\Database\IExpression|string myField Database field to be compared against value
     * @param \Cake\Database\IExpression|array|string myValues the value to be bound to myField for comparison
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function notInOrNull(myField, myValues, ?string myType = null) {
        $or = new static([], [], 'OR');
        $or
            .notIn(myField, myValues, myType)
            .isNull(myField);

        return this.add($or);
    }

    /**
     * Adds a new condition to the expression object in the form "EXISTS (...)".
     *
     * @param \Cake\Database\IExpression $expression the inner query
     * @return this
     */
    function exists(IExpression $expression) {
        return this.add(new UnaryExpression('EXISTS', $expression, UnaryExpression::PREFIX));
    }

    /**
     * Adds a new condition to the expression object in the form "NOT EXISTS (...)".
     *
     * @param \Cake\Database\IExpression $expression the inner query
     * @return this
     */
    function notExists(IExpression $expression) {
        return this.add(new UnaryExpression('NOT EXISTS', $expression, UnaryExpression::PREFIX));
    }

    /**
     * Adds a new condition to the expression object in the form
     * "field BETWEEN from AND to".
     *
     * @param \Cake\Database\IExpression|string myField The field name to compare for values inbetween the range.
     * @param mixed $from The initial value of the range.
     * @param mixed $to The ending value in the comparison range.
     * @param string|null myType the type name for myValue as configured using the Type map.
     * @return this
     */
    function between(myField, $from, $to, myType = null) {
        if (myType === null) {
            myType = this._calculateType(myField);
        }

        return this.add(new BetweenExpression(myField, $from, $to, myType));
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "AND"
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions to be joined with AND
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return \Cake\Database\Expression\QueryExpression
     */
    function and($conditions, myTypes = []) {
        if ($conditions instanceof Closure) {
            return $conditions(new static([], this.getTypeMap().setTypes(myTypes)));
        }

        return new static($conditions, this.getTypeMap().setTypes(myTypes));
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "OR"
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions to be joined with OR
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return \Cake\Database\Expression\QueryExpression
     */
    function or($conditions, myTypes = []) {
        if ($conditions instanceof Closure) {
            return $conditions(new static([], this.getTypeMap().setTypes(myTypes), 'OR'));
        }

        return new static($conditions, this.getTypeMap().setTypes(myTypes), 'OR');
    }

    // phpcs:disable PSR1.Methods.CamelCapsMethodName.NotCamelCaps

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "AND"
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions to be joined with AND
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return \Cake\Database\Expression\QueryExpression
     * @deprecated 4.0.0 Use {@link and()} instead.
     */
    function and_($conditions, myTypes = []) {
        deprecationWarning('QueryExpression::and_() is deprecated use and() instead.');

        return this.and($conditions, myTypes);
    }

    /**
     * Returns a new QueryExpression object containing all the conditions passed
     * and set up the conjunction to be "OR"
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions to be joined with OR
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return \Cake\Database\Expression\QueryExpression
     * @deprecated 4.0.0 Use {@link or()} instead.
     */
    function or_($conditions, myTypes = []) {
        deprecationWarning('QueryExpression::or_() is deprecated use or() instead.');

        return this.or($conditions, myTypes);
    }

    // phpcs:enable

    /**
     * Adds a new set of conditions to this level of the tree and negates
     * the final result by prepending a NOT, it will look like
     * "NOT ( (condition1) AND (conditions2) )" conjunction depends on the one
     * currently configured for this object.
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions to be added and negated
     * @param array<string, string> myTypes Associative array of fields pointing to the type of the
     * values that are being passed. Used for correctly binding values to statements.
     * @return this
     */
    function not($conditions, myTypes = []) {
        return this.add(['NOT' => $conditions], myTypes);
    }

    /**
     * Returns the number of internal conditions that are stored in this expression.
     * Useful to determine if this expression object is void or it will generate
     * a non-empty string when compiled
     *
     * @return int
     */
    int count() {
        return count(this._conditions);
    }

    /**
     * Builds equal condition or assignment with identifier wrapping.
     *
     * @param string $leftField Left join condition field name.
     * @param string $rightField Right join condition field name.
     * @return this
     */
    function equalFields(string $leftField, string $rightField) {
        $wrapIdentifier = function (myField) {
            if (myField instanceof IExpression) {
                return myField;
            }

            return new IdentifierExpression(myField);
        };

        return this.eq($wrapIdentifier($leftField), $wrapIdentifier($rightField));
    }


    function sql(ValueBinder $binder): string
    {
        $len = this.count();
        if ($len === 0) {
            return '';
        }
        $conjunction = this._conjunction;
        myTemplate = $len === 1 ? '%s' : '(%s)';
        $parts = [];
        foreach (this._conditions as $part) {
            if ($part instanceof Query) {
                $part = '(' . $part.sql($binder) . ')';
            } elseif ($part instanceof IExpression) {
                $part = $part.sql($binder);
            }
            if ($part !== '') {
                $parts[] = $part;
            }
        }

        return sprintf(myTemplate, implode(" $conjunction ", $parts));
    }


    function traverse(Closure $callback) {
        foreach (this._conditions as $c) {
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
     * The callable function is required to return a value with which the currently
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
        foreach (this._conditions as $k => $c) {
            myKey = &$k;
            $part = $callback($c, myKey);
            if ($part !== null) {
                $parts[myKey] = $part;
            }
        }
        this._conditions = $parts;

        return this;
    }

    /**
     * Check whether a callable is acceptable.
     *
     * We don't accept ['class', 'method'] style callbacks,
     * as they often contain user input and arrays of strings
     * are easy to sneak in.
     *
     * @param \Cake\Database\IExpression|callable|array|string $callable The callable to check.
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
    bool hasNestedExpression() {
        foreach (this._conditions as $c) {
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
     * @param array<string, string> myTypes list of types associated on fields referenced in $conditions
     * @return void
     */
    protected auto _addConditions(array $conditions, array myTypes): void
    {
        $operators = ['and', 'or', 'xor'];

        myTypeMap = this.getTypeMap().setTypes(myTypes);

        foreach ($conditions as $k => $c) {
            $numericKey = is_numeric($k);

            if ($c instanceof Closure) {
                $expr = new static([], myTypeMap);
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
                $isNot = $normalizedKey === 'not';
            }

            if (($isOperator || $isNot) && ($isArray || $c instanceof Countable) && count($c) === 0) {
                continue;
            }

            if ($numericKey && $c instanceof IExpression) {
                this._conditions[] = $c;
                continue;
            }

            if ($numericKey && is_string($c)) {
                this._conditions[] = $c;
                continue;
            }

            if ($numericKey && $isArray || $isOperator) {
                this._conditions[] = new static($c, myTypeMap, $numericKey ? 'AND' : $k);
                continue;
            }

            if ($isNot) {
                this._conditions[] = new UnaryExpression('NOT', new static($c, myTypeMap));
                continue;
            }

            if (!$numericKey) {
                this._conditions[] = this._parseCondition($k, $c);
            }
        }
    }

    /**
     * Parses a string conditions by trying to extract the operator inside it if any
     * and finally returning either an adequate QueryExpression object or a plain
     * string representation of the condition. This function is responsible for
     * generating the placeholders and replacing the values by them, while storing
     * the value elsewhere for future binding.
     *
     * @param string myField The value from which the actual field and operator will
     * be extracted.
     * @param mixed myValue The value to be bound to a placeholder for the field
     * @return \Cake\Database\IExpression
     * @throws \InvalidArgumentException If operator is invalid or missing on NULL usage.
     */
    protected auto _parseCondition(string myField, myValue) {
        myField = trim(myField);
        $operator = '=';
        $expression = myField;

        $spaces = substr_count(myField, ' ');
        // Handle operators with a space in them like `is not` and `not like`
        if ($spaces > 1) {
            $parts = explode(' ', myField);
            if (preg_match('/(is not|not \w+)$/i', myField)) {
                $last = array_pop($parts);
                $second = array_pop($parts);
                array_push($parts, strtolower("{$second} {$last}"));
            }
            $operator = array_pop($parts);
            $expression = implode(' ', $parts);
        } elseif ($spaces == 1) {
            $parts = explode(' ', myField, 2);
            [$expression, $operator] = $parts;
            $operator = strtolower(trim($operator));
        }
        myType = this.getTypeMap().type($expression);

        myTypeMultiple = (is_string(myType) && strpos(myType, '[]') !== false);
        if (in_array($operator, ['in', 'not in']) || myTypeMultiple) {
            myType = myType ?: 'string';
            if (!myTypeMultiple) {
                myType .= '[]';
            }
            $operator = $operator === '=' ? 'IN' : $operator;
            $operator = $operator === '!=' ? 'NOT IN' : $operator;
            myTypeMultiple = true;
        }

        if (myTypeMultiple) {
            myValue = myValue instanceof IExpression ? myValue : (array)myValue;
        }

        if ($operator === 'is' && myValue === null) {
            return new UnaryExpression(
                'IS NULL',
                new IdentifierExpression($expression),
                UnaryExpression::POSTFIX
            );
        }

        if ($operator === 'is not' && myValue === null) {
            return new UnaryExpression(
                'IS NOT NULL',
                new IdentifierExpression($expression),
                UnaryExpression::POSTFIX
            );
        }

        if ($operator === 'is' && myValue !== null) {
            $operator = '=';
        }

        if ($operator === 'is not' && myValue !== null) {
            $operator = '!=';
        }

        if (myValue === null && this._conjunction !== ',') {
            throw new InvalidArgumentException(
                sprintf('Expression `%s` is missing operator (IS, IS NOT) with `null` value.', $expression)
            );
        }

        return new ComparisonExpression($expression, myValue, myType, $operator);
    }

    /**
     * Returns the type name for the passed field if it was stored in the typeMap
     *
     * @param \Cake\Database\IExpression|string myField The field name to get a type for.
     * @return string|null The computed type or null, if the type is unknown.
     */
    protected string _calculateType(myField) {
        myField = myField instanceof IdentifierExpression ? myField.getIdentifier() : myField;
        if (is_string(myField)) {
            return this.getTypeMap().type(myField);
        }

        return null;
    }

    /**
     * Clone this object and its subtree of expressions.
     *
     * @return void
     */
    auto __clone() {
        foreach (this._conditions as $i => $condition) {
            if ($condition instanceof IExpression) {
                this._conditions[$i] = clone $condition;
            }
        }
    }
}
