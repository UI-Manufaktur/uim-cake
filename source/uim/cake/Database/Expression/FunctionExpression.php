
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.Type\ExpressionTypeCasterTrait;
import uim.cake.databases.TypedResultInterface;
import uim.cake.databases.TypedResultTrait;
import uim.cake.databases.ValueBinder;

/**
 * This class represents a function call string in a SQL statement. Calls can be
 * constructed by passing the name of the function and a list of params.
 * For security reasons, all params passed are quoted by default unless
 * explicitly told otherwise.
 */
class FunctionExpression : QueryExpression : TypedResultInterface
{
    use ExpressionTypeCasterTrait;
    use TypedResultTrait;

    /**
     * The name of the function to be constructed when generating the SQL string
     *
     * @var string
     */
    protected $_name;

    /**
     * Constructor. Takes a name for the function to be invoked and a list of params
     * to be passed into the function. Optionally you can pass a list of types to
     * be used for each bound param.
     *
     * By default, all params that are passed will be quoted. If you wish to use
     * literal arguments, you need to explicitly hint this function.
     *
     * ### Examples:
     *
     * `$f = new FunctionExpression("CONCAT", ["CakePHP", " rules"]);`
     *
     * Previous line will generate `CONCAT("CakePHP", " rules")`
     *
     * `$f = new FunctionExpression("CONCAT", ["name": "literal", " rules"]);`
     *
     * Will produce `CONCAT(name, " rules")`
     *
     * @param string $name the name of the function to be constructed
     * @param array $params list of arguments to be passed to the function
     * If associative the key would be used as argument when value is "literal"
     * @param array<string, string>|array<string|null> $types Associative array of types to be associated with the
     * passed arguments
     * @param string $returnType The return type of this expression
     */
    this(string $name, array $params = [], array $types = [], string $returnType = "string") {
        _name = $name;
        _returnType = $returnType;
        super(($params, $types, ",");
    }

    /**
     * Sets the name of the SQL function to be invoke in this expression.
     *
     * @param string $name The name of the function
     * @return this
     */
    function setName(string $name) {
        _name = $name;

        return this;
    }

    /**
     * Gets the name of the SQL function to be invoke in this expression.
     *
     * @return string
     */
    string getName(): string
    {
        return _name;
    }

    /**
     * Adds one or more arguments for the function call.
     *
     * @param array $conditions list of arguments to be passed to the function
     * If associative the key would be used as argument when value is "literal"
     * @param array<string, string> $types Associative array of types to be associated with the
     * passed arguments
     * @param bool $prepend Whether to prepend or append to the list of arguments
     * @see uim.cake.Database\Expression\FunctionExpression::__construct() for more details.
     * @return this
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function add($conditions, array $types = [], bool $prepend = false) {
        $put = $prepend ? "array_unshift" : "array_push";
        $typeMap = this.getTypeMap().setTypes($types);
        foreach ($conditions as $k: $p) {
            if ($p == "literal") {
                $put(_conditions, $k);
                continue;
            }

            if ($p == "identifier") {
                $put(_conditions, new IdentifierExpression($k));
                continue;
            }

            $type = $typeMap.type($k);

            if ($type != null && !$p instanceof IExpression) {
                $p = _castToExpression($p, $type);
            }

            if ($p instanceof IExpression) {
                $put(_conditions, $p);
                continue;
            }

            $put(_conditions, ["value": $p, "type": $type]);
        }

        return this;
    }


    function sql(ValueBinder $binder): string
    {
        $parts = [];
        foreach (_conditions as $condition) {
            if ($condition instanceof Query) {
                $condition = sprintf("(%s)", $condition.sql($binder));
            } elseif ($condition instanceof IExpression) {
                $condition = $condition.sql($binder);
            } elseif (is_array($condition)) {
                $p = $binder.placeholder("param");
                $binder.bind($p, $condition["value"], $condition["type"]);
                $condition = $p;
            }
            $parts[] = $condition;
        }

        return _name . sprintf("(%s)", implode(
            _conjunction . " ",
            $parts
        ));
    }

    /**
     * The name of the function is in itself an expression to generate, thus
     * always adding 1 to the amount of expressions stored in this object.
     *
     * @return int
     */
    function count(): int
    {
        return 1 + count(_conditions);
    }
}
