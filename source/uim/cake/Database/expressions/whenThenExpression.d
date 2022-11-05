module uim.cake.databases.expressions;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.Type\ExpressionTypeCasterTrait;
import uim.cake.databases.TypeMap;
import uim.cake.databases.ValueBinder;
use Closure;
use InvalidArgumentException;
use LogicException;

/**
 * Represents a SQL when/then clause with a fluid API
 */
class WhenThenExpression : IExpression
{
    use CaseExpressionTrait;
    use ExpressionTypeCasterTrait;

    /**
     * The names of the clauses that are valid for use with the
     * `clause()` method.
     *
     * @var array<string>
     */
    protected $validClauseNames = [
        'when',
        'then',
    ];

    /**
     * The type map to use when using an array of conditions for the
     * `WHEN` value.
     *
     * @var \Cake\Database\TypeMap
     */
    protected $_typeMap;

    /**
     * Then `WHEN` value.
     *
     * @var \Cake\Database\IExpression|object|scalar|null
     */
    protected $when = null;

    /**
     * The `WHEN` value type.
     *
     * @var array|string|null
     */
    protected $whenType = null;

    /**
     * The `THEN` value.
     *
     * @var \Cake\Database\IExpression|object|scalar|null
     */
    protected $then = null;

    /**
     * Whether the `THEN` value has been defined, eg whether `then()`
     * has been invoked.
     *
     * @var bool
     */
    protected $hasThenBeenDefined = false;

    /**
     * The `THEN` result type.
     *
     * @var string|null
     */
    protected $thenType = null;

    /**
     * Constructor.
     *
     * @param \Cake\Database\TypeMap|null myTypeMap The type map to use when using an array of conditions for the `WHEN`
     *  value.
     */
    this(?TypeMap myTypeMap = null) {
        if (myTypeMap === null) {
            myTypeMap = new TypeMap();
        }
        this._typeMap = myTypeMap;
    }

    /**
     * Sets the `WHEN` value.
     *
     * @param \Cake\Database\IExpression|object|array|scalar $when The `WHEN` value. When using an array of
     *  conditions, it must be compatible with `\Cake\Database\Query::where()`. Note that this argument is _not_
     *  completely safe for use with user data, as a user supplied array would allow for raw SQL to slip in! If you
     *  plan to use user data, either pass a single type for the `myType` argument (which forces the `$when` value to be
     *  a non-array, and then always binds the data), use a conditions array where the user data is only passed on the
     *  value side of the array entries, or custom bindings!
     * @param array<string, string>|string|null myType The when value type. Either an associative array when using array style
     *  conditions, or else a string. If no type is provided, the type will be tried to be inferred from the value.
     * @return this
     * @throws \InvalidArgumentException In case the `$when` argument is neither a non-empty array, nor a scalar value,
     *  an object, or an instance of `\Cake\Database\IExpression`.
     * @throws \InvalidArgumentException In case the `myType` argument is neither an array, a string, nor null.
     * @throws \InvalidArgumentException In case the `$when` argument is an array, and the `myType` argument is neither
     * an array, nor null.
     * @throws \InvalidArgumentException In case the `$when` argument is a non-array value, and the `myType` argument is
     * neither a string, nor null.
     * @see CaseStatementExpression::when() for a more detailed usage explanation.
     */
    function when($when, myType = null) {
        if (
            !(is_array($when) && !empty($when)) &&
            !is_scalar($when) &&
            !is_object($when)
        ) {
            throw new InvalidArgumentException(sprintf(
                'The `$when` argument must be either a non-empty array, a scalar value, an object, ' .
                'or an instance of `\%s`, `%s` given.',
                IExpression::class,
                is_array($when) ? '[]' : getTypeName($when)
            ));
        }

        if (
            myType !== null &&
            !is_array(myType) &&
            !is_string(myType)
        ) {
            throw new InvalidArgumentException(sprintf(
                'The `myType` argument must be either an array, a string, or `null`, `%s` given.',
                getTypeName(myType)
            ));
        }

        if (is_array($when)) {
            if (
                myType !== null &&
                !is_array(myType)
            ) {
                throw new InvalidArgumentException(sprintf(
                    'When using an array for the `$when` argument, the `myType` argument must be an ' .
                    'array too, `%s` given.',
                    getTypeName(myType)
                ));
            }

            // avoid dirtying the type map for possible consecutive `when()` calls
            myTypeMap = clone this._typeMap;
            if (
                is_array(myType) &&
                count(myType) > 0
            ) {
                myTypeMap = myTypeMap.setTypes(myType);
            }

            $when = new QueryExpression($when, myTypeMap);
        } else {
            if (
                myType !== null &&
                !is_string(myType)
            ) {
                throw new InvalidArgumentException(sprintf(
                    'When using a non-array value for the `$when` argument, the `myType` argument must ' .
                    'be a string, `%s` given.',
                    getTypeName(myType)
                ));
            }

            if (
                myType === null &&
                !($when instanceof IExpression)
            ) {
                myType = this.inferType($when);
            }
        }

        this.when = $when;
        this.whenType = myType;

        return this;
    }

    /**
     * Sets the `THEN` result value.
     *
     * @param \Cake\Database\IExpression|object|scalar|null myResult The result value.
     * @param string|null myType The result type. If no type is provided, the type will be inferred from the given
     *  result value.
     * @return this
     */
    function then(myResult, ?string myType = null) {
        if (
            myResult !== null &&
            !is_scalar(myResult) &&
            !(is_object(myResult) && !(myResult instanceof Closure))
        ) {
            throw new InvalidArgumentException(sprintf(
                'The `myResult` argument must be either `null`, a scalar value, an object, ' .
                'or an instance of `\%s`, `%s` given.',
                IExpression::class,
                getTypeName(myResult)
            ));
        }

        this.then = myResult;

        if (myType === null) {
            myType = this.inferType(myResult);
        }

        this.thenType = myType;

        this.hasThenBeenDefined = true;

        return this;
    }

    /**
     * Returns the expression's result value type.
     *
     * @return string|null
     * @see WhenThenExpression::then()
     */
    string getResultType() {
        return this.thenType;
    }

    /**
     * Returns the available data for the given clause.
     *
     * ### Available clauses
     *
     * The following clause names are available:
     *
     * * `when`: The `WHEN` value.
     * * `then`: The `THEN` result value.
     *
     * @param string $clause The name of the clause to obtain.
     * @return \Cake\Database\IExpression|object|scalar|null
     * @throws \InvalidArgumentException In case the given clause name is invalid.
     */
    function clause(string $clause) {
        if (!in_array($clause, this.validClauseNames, true)) {
            throw new InvalidArgumentException(
                sprintf(
                    'The `$clause` argument must be one of `%s`, the given value `%s` is invalid.',
                    implode('`, `', this.validClauseNames),
                    $clause
                )
            );
        }

        return this.{$clause};
    }


    function sql(ValueBinder $binder): string
    {
        if (this.when === null) {
            throw new LogicException('Case expression has incomplete when clause. Missing `when()`.');
        }

        if (!this.hasThenBeenDefined) {
            throw new LogicException('Case expression has incomplete when clause. Missing `then()` after `when()`.');
        }

        $when = this.when;
        if (
            is_string(this.whenType) &&
            !($when instanceof IExpression)
        ) {
            $when = this._castToExpression($when, this.whenType);
        }
        if ($when instanceof Query) {
            $when = sprintf('(%s)', $when.sql($binder));
        } elseif ($when instanceof IExpression) {
            $when = $when.sql($binder);
        } else {
            $placeholder = $binder.placeholder('c');
            if (is_string(this.whenType)) {
                $whenType = this.whenType;
            } else {
                $whenType = null;
            }
            $binder.bind($placeholder, $when, $whenType);
            $when = $placeholder;
        }

        $then = this.compileNullableValue($binder, this.then, this.thenType);

        return "WHEN $when THEN $then";
    }


    function traverse(Closure $callback) {
        if (this.when instanceof IExpression) {
            $callback(this.when);
            this.when.traverse($callback);
        }

        if (this.then instanceof IExpression) {
            $callback(this.then);
            this.then.traverse($callback);
        }

        return this;
    }

    /**
     * Clones the inner expression objects.
     *
     * @return void
     */
    auto __clone() {
        if (this.when instanceof IExpression) {
            this.when = clone this.when;
        }

        if (this.then instanceof IExpression) {
            this.then = clone this.then;
        }
    }
}
