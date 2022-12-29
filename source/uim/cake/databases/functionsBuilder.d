module uim.cake.databases.functionsBuilder;

@safe:
import uim.cake;

/**
 * Contains methods related to generating FunctionExpression objects
 * with most commonly used SQL functions.
 * This acts as a factory for FunctionExpression objects.
 */
class FunctionsBuilder {
    /**
     * Returns a FunctionExpression representing a call to SQL RAND function.
     *
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function rand(): FunctionExpression {
        return new FunctionExpression("RAND", [], [], "float");
    }

    /**
     * Returns a AggregateExpression representing a call to SQL SUM function.
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function sum($expression, myTypes = []): AggregateExpression
    {
        $returnType = "float";
        if (current(myTypes) == "integer") {
            $returnType = "integer";
        }

        return this.aggregate("SUM", this.toLiteralParam($expression), myTypes, $returnType);
    }

    /**
     * Returns a AggregateExpression representing a call to SQL AVG function.
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function avg($expression, myTypes = []): AggregateExpression
    {
        return this.aggregate("AVG", this.toLiteralParam($expression), myTypes, "float");
    }

    /**
     * Returns a AggregateExpression representing a call to SQL MAX function.
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function max($expression, myTypes = []): AggregateExpression
    {
        return this.aggregate("MAX", this.toLiteralParam($expression), myTypes, current(myTypes) ?: "float");
    }

    /**
     * Returns a AggregateExpression representing a call to SQL MIN function.
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function min($expression, myTypes = []): AggregateExpression
    {
        return this.aggregate("MIN", this.toLiteralParam($expression), myTypes, current(myTypes) ?: "float");
    }

    /**
     * Returns a AggregateExpression representing a call to SQL COUNT function.
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function count($expression, myTypes = []): AggregateExpression
    {
        return this.aggregate("COUNT", this.toLiteralParam($expression), myTypes, "integer");
    }

    /**
     * Returns a FunctionExpression representing a string concatenation
     *
     * @param array $args List of strings or expressions to concatenate
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function concat(array $args, array myTypes = []): FunctionExpression
    {
        return new FunctionExpression("CONCAT", $args, myTypes, "string");
    }

    /**
     * Returns a FunctionExpression representing a call to SQL COALESCE function.
     *
     * @param array $args List of expressions to evaluate as function parameters
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function coalesce(array $args, array myTypes = []): FunctionExpression
    {
        return new FunctionExpression("COALESCE", $args, myTypes, current(myTypes) ?: "string");
    }

    /**
     * Returns a FunctionExpression representing a SQL CAST.
     *
     * The `myType` parameter is a SQL type. The return type for the returned expression
     * is the default type name. Use `setReturnType()` to update it.
     *
     * @param uim.cake.Database\IExpression|string myField Field or expression to cast.
     * @param string myType The SQL data type
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function cast(myField, string myType = ""): FunctionExpression
    {
        if (is_array(myField)) {
            deprecationWarning(
                "Build cast function by FunctionsBuilder::cast(array $args) is deprecated. " .
                "Use FunctionsBuilder::cast(myField, string myType) instead."
            );

            return new FunctionExpression("CAST", myField);
        }

        if (empty(myType)) {
            throw new InvalidArgumentException("The `myType` in a cast cannot be empty.");
        }

        $expression = new FunctionExpression("CAST", this.toLiteralParam(myField));
        $expression.setConjunction(" AS").add([myType: "literal"]);

        return $expression;
    }

    /**
     * Returns a FunctionExpression representing the difference in days between
     * two dates.
     *
     * @param array $args List of expressions to obtain the difference in days.
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function dateDiff(array $args, array myTypes = []): FunctionExpression
    {
        return new FunctionExpression("DATEDIFF", $args, myTypes, "integer");
    }

    /**
     * Returns the specified date part from the SQL expression.
     *
     * @param string part Part of the date to return.
     * @param uim.cake.Database\IExpression|string expression Expression to obtain the date part from.
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function datePart(string part, $expression, array myTypes = []): FunctionExpression
    {
        return this.extract($part, $expression, myTypes);
    }

    /**
     * Returns the specified date part from the SQL expression.
     *
     * @param string part Part of the date to return.
     * @param uim.cake.Database\IExpression|string expression Expression to obtain the date part from.
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function extract(string part, $expression, array myTypes = []): FunctionExpression
    {
        $expression = new FunctionExpression("EXTRACT", this.toLiteralParam($expression), myTypes, "integer");
        $expression.setConjunction(" FROM").add([$part: "literal"], [], true);

        return $expression;
    }

    /**
     * Add the time unit to the date expression
     *
     * @param uim.cake.Database\IExpression|string expression Expression to obtain the date part from.
     * @param string|int myValue Value to be added. Use negative to subtract.
     * @param string unit Unit of the value e.g. hour or day.
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function dateAdd($expression, myValue, string unit, array myTypes = []): FunctionExpression
    {
        if (!is_numeric(myValue)) {
            myValue = 0;
        }
        $interval = myValue . " " . $unit;
        $expression = new FunctionExpression("DATE_ADD", this.toLiteralParam($expression), myTypes, "datetime");
        $expression.setConjunction(", INTERVAL").add([$interval: "literal"]);

        return $expression;
    }

    /**
     * Returns a FunctionExpression representing a call to SQL WEEKDAY function.
     * 1 - Sunday, 2 - Monday, 3 - Tuesday...
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function dayOfWeek($expression, myTypes = []): FunctionExpression
    {
        return new FunctionExpression("DAYOFWEEK", this.toLiteralParam($expression), myTypes, "integer");
    }

    /**
     * Returns a FunctionExpression representing a call to SQL WEEKDAY function.
     * 1 - Sunday, 2 - Monday, 3 - Tuesday...
     *
     * @param uim.cake.Database\IExpression|string expression the function argument
     * @param array myTypes list of types to bind to the arguments
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function weekday($expression, myTypes = []): FunctionExpression
    {
        return this.dayOfWeek($expression, myTypes);
    }

    /**
     * Returns a FunctionExpression representing a call that will return the current
     * date and time. By default it returns both date and time, but you can also
     * make it generate only the date or only the time.
     *
     * @param string myType (datetime|date|time)
     * @return \Cake\Database\Expression\FunctionExpression
     */
    function now(string myType = "datetime"): FunctionExpression
    {
        if (myType == "datetime") {
            return new FunctionExpression("NOW", [], [], "datetime");
        }
        if (myType == "date") {
            return new FunctionExpression("CURRENT_DATE", [], [], "date");
        }
        if (myType == "time") {
            return new FunctionExpression("CURRENT_TIME", [], [], "time");
        }

        throw new InvalidArgumentException("Invalid argument for FunctionsBuilder::now(): " . myType);
    }

    /**
     * Returns an AggregateExpression representing call to SQL ROW_NUMBER().
     *
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function rowNumber(): AggregateExpression
    {
        return (new AggregateExpression("ROW_NUMBER", [], [], "integer")).over();
    }

    /**
     * Returns an AggregateExpression representing call to SQL LAG().
     *
     * @param uim.cake.Database\IExpression|string expression The value evaluated at offset
     * @param int $offset The row offset
     * @param mixed $default The default value if offset doesn"t exist
     * @param string myType The output type of the lag expression. Defaults to float.
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function lag($expression, int $offset, $default = null, myType = null): AggregateExpression
    {
        myParams = this.toLiteralParam($expression) + [$offset: "literal"];
        if ($default  !is null) {
            myParams[] = $default;
        }

        myTypes = [];
        if (myType  !is null) {
            myTypes = [myType, "integer", myType];
        }

        return (new AggregateExpression("LAG", myParams, myTypes, myType ?? "float")).over();
    }

    /**
     * Returns an AggregateExpression representing call to SQL LEAD().
     *
     * @param uim.cake.Database\IExpression|string expression The value evaluated at offset
     * @param int $offset The row offset
     * @param mixed $default The default value if offset doesn"t exist
     * @param string myType The output type of the lead expression. Defaults to float.
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function lead($expression, int $offset, $default = null, myType = null): AggregateExpression
    {
        myParams = this.toLiteralParam($expression) + [$offset: "literal"];
        if ($default  !is null) {
            myParams[] = $default;
        }

        myTypes = [];
        if (myType  !is null) {
            myTypes = [myType, "integer", myType];
        }

        return (new AggregateExpression("LEAD", myParams, myTypes, myType ?? "float")).over();
    }

    /**
     * Helper method to create arbitrary SQL aggregate function calls.
     *
     * @param string myName The SQL aggregate function name
     * @param array myParams Array of arguments to be passed to the function.
     *     Can be an associative array with the literal value or identifier:
     *     `["value":"literal"]` or `["value":"identifier"]
     * @param array myTypes Array of types that match the names used in `myParams`:
     *     `["name":"type"]`
     * @param string return Return type of the entire expression. Defaults to float.
     * @return \Cake\Database\Expression\AggregateExpression
     */
    function aggregate(string myName, array myParams = [], array myTypes = [], string return = "float") {
        return new AggregateExpression(myName, myParams, myTypes, $return);
    }

    /**
     * Magic method dispatcher to create custom SQL function calls
     *
     * @param string myName the SQL function name to construct
     * @param array $args list with up to 3 arguments, first one being an array with
     * parameters for the SQL function, the second one a list of types to bind to those
     * params, and the third one the return type of the function
     * @return \Cake\Database\Expression\FunctionExpression
     */
    auto __call(string myName, array $args): FunctionExpression
    {
        return new FunctionExpression(myName, ...$args);
    }

    /**
     * Creates function parameter array from expression or string literal.
     *
     * @param uim.cake.Database\IExpression|string expression function argument
     * @return array<\Cake\Database\IExpression|string>
     */
    protected auto toLiteralParam($expression) {
        if (is_string($expression)) {
            return [$expression: "literal"];
        }

        return [$expression];
    }
}
