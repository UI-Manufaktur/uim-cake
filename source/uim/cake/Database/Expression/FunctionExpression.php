module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.Query;
import uim.cake.database.Type\ExpressionTypeCasterTrait;
import uim.cake.database.TypedResultInterface;
import uim.cake.database.TypedResultTrait;
import uim.cake.database.ValueBinder;

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
     * `$f = new FunctionExpression('CONCAT', ['CakePHP', ' rules']);`
     *
     * Previous line will generate `CONCAT('CakePHP', ' rules')`
     *
     * `$f = new FunctionExpression('CONCAT', ['name' => 'literal', ' rules']);`
     *
     * Will produce `CONCAT(name, ' rules')`
     *
     * @param string myName the name of the function to be constructed
     * @param array myParams list of arguments to be passed to the function
     * If associative the key would be used as argument when value is 'literal'
     * @param array<string, string>|array<string|null> myTypes Associative array of types to be associated with the
     * passed arguments
     * @param string $returnType The return type of this expression
     */
    this(string myName, array myParams = [], array myTypes = [], string $returnType = 'string')
    {
        this._name = myName;
        this._returnType = $returnType;
        super.this(myParams, myTypes, ',');
    }

    /**
     * Sets the name of the SQL function to be invoke in this expression.
     *
     * @param string myName The name of the function
     * @return this
     */
    auto setName(string myName)
    {
        this._name = myName;

        return this;
    }

    /**
     * Gets the name of the SQL function to be invoke in this expression.
     *
     * @return string
     */
    auto getName(): string
    {
        return this._name;
    }

    /**
     * Adds one or more arguments for the function call.
     *
     * @param array $conditions list of arguments to be passed to the function
     * If associative the key would be used as argument when value is 'literal'
     * @param array<string, string> myTypes Associative array of types to be associated with the
     * passed arguments
     * @param bool $prepend Whether to prepend or append to the list of arguments
     * @see \Cake\Database\Expression\FunctionExpression::this() for more details.
     * @return this
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    function add($conditions, array myTypes = [], bool $prepend = false)
    {
        $put = $prepend ? 'array_unshift' : 'array_push';
        myTypeMap = this.getTypeMap().setTypes(myTypes);
        foreach ($conditions as $k => $p) {
            if ($p === 'literal') {
                $put(this._conditions, $k);
                continue;
            }

            if ($p === 'identifier') {
                $put(this._conditions, new IdentifierExpression($k));
                continue;
            }

            myType = myTypeMap.type($k);

            if (myType !== null && !$p instanceof IExpression) {
                $p = this._castToExpression($p, myType);
            }

            if ($p instanceof IExpression) {
                $put(this._conditions, $p);
                continue;
            }

            $put(this._conditions, ['value' => $p, 'type' => myType]);
        }

        return this;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $parts = [];
        foreach (this._conditions as $condition) {
            if ($condition instanceof Query) {
                $condition = sprintf('(%s)', $condition.sql($binder));
            } elseif ($condition instanceof IExpression) {
                $condition = $condition.sql($binder);
            } elseif (is_array($condition)) {
                $p = $binder.placeholder('param');
                $binder.bind($p, $condition['value'], $condition['type']);
                $condition = $p;
            }
            $parts[] = $condition;
        }

        return this._name . sprintf('(%s)', implode(
            this._conjunction . ' ',
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
        return 1 + count(this._conditions);
    }
}
