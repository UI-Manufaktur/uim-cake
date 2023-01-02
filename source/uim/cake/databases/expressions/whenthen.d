module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.Query;
import uim.cake.databases.types.ExpressionTypeCasterTrait;
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
        "when",
        "then",
    ];

    /**
     * The type map to use when using an array of conditions for the
     * `WHEN` value.
     *
     * @var uim.cake.databases.TypeMap
     */
    protected $_typeMap;

    /**
     * Then `WHEN` value.
     *
     * @var uim.cake.databases.IExpression|object|scalar|null
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
     * @var uim.cake.databases.IExpression|object|scalar|null
     */
    protected $then = null;

    /**
     * Whether the `THEN` value has been defined, eg whether `then()`
     * has been invoked.
     *
     */
    protected bool $hasThenBeenDefined = false;

    /**
     * The `THEN` result type.
     *
     * @var string|null
     */
    protected $thenType = null;

    /**
     * Constructor.
     *
     * @param uim.cake.databases.TypeMap|null $typeMap The type map to use when using an array of conditions for the `WHEN`
     *  value.
     */
    this(?TypeMap $typeMap = null) {
        if ($typeMap == null) {
            $typeMap = new TypeMap();
        }
        _typeMap = $typeMap;
    }

    /**
     * Sets the `WHEN` value.
     *
     * @param uim.cake.databases.IExpression|object|array|scalar $when The `WHEN` value. When using an array of
     *  conditions, it must be compatible with `uim.cake.databases.Query::where()`. Note that this argument is _not_
     *  completely safe for use with user data, as a user supplied array would allow for raw SQL to slip in! If you
     *  plan to use user data, either pass a single type for the `$type` argument (which forces the `$when` value to be
     *  a non-array, and then always binds the data), use a conditions array where the user data is only passed on the
     *  value side of the array entries, or custom bindings!
     * @param array<string, string>|string|null $type The when value type. Either an associative array when using array style
     *  conditions, or else a string. If no type is provided, the type will be tried to be inferred from the value.
     * @return this
     * @throws \InvalidArgumentException In case the `$when` argument is neither a non-empty array, nor a scalar value,
     *  an object, or an instance of `uim.cake.databases.IExpression`.
     * @throws \InvalidArgumentException In case the `$type` argument is neither an array, a string, nor null.
     * @throws \InvalidArgumentException In case the `$when` argument is an array, and the `$type` argument is neither
     * an array, nor null.
     * @throws \InvalidArgumentException In case the `$when` argument is a non-array value, and the `$type` argument is
     * neither a string, nor null.
     * @see CaseStatementExpression::when() for a more detailed usage explanation.
     */
    function when($when, $type = null) {
        if (
            !(is_array($when) && !empty($when)) &&
            !is_scalar($when) &&
            !is_object($when)
        ) {
            throw new InvalidArgumentException(sprintf(
                "The `$when` argument must be either a non-empty array, a scalar value, an object, " ~
                "or an instance of `\%s`, `%s` given.",
                IExpression::class,
                is_array($when) ? "[]" : getTypeName($when) // @phpstan-ignore-line
            ));
        }

        if (
            $type != null &&
            !is_array($type) &&
            !is_string($type)
        ) {
            throw new InvalidArgumentException(sprintf(
                "The `$type` argument must be either an array, a string, or `null`, `%s` given.",
                getTypeName($type)
            ));
        }

        if (is_array($when)) {
            if (
                $type != null &&
                !is_array($type)
            ) {
                throw new InvalidArgumentException(sprintf(
                    "When using an array for the `$when` argument, the `$type` argument must be an " ~
                    "array too, `%s` given.",
                    getTypeName($type)
                ));
            }

            // avoid dirtying the type map for possible consecutive `when()` calls
            $typeMap = clone _typeMap;
            if (
                is_array($type) &&
                count($type) > 0
            ) {
                $typeMap = $typeMap.setTypes($type);
            }

            $when = new QueryExpression($when, $typeMap);
        } else {
            if (
                $type != null &&
                !is_string($type)
            ) {
                throw new InvalidArgumentException(sprintf(
                    "When using a non-array value for the `$when` argument, the `$type` argument must " ~
                    "be a string, `%s` given.",
                    getTypeName($type)
                ));
            }

            if (
                $type == null &&
                !($when instanceof IExpression)
            ) {
                $type = this.inferType($when);
            }
        }

        this.when = $when;
        this.whenType = $type;

        return this;
    }

    /**
     * Sets the `THEN` result value.
     *
     * @param uim.cake.databases.IExpression|object|scalar|null $result The result value.
     * @param string|null $type The result type. If no type is provided, the type will be inferred from the given
     *  result value.
     * @return this
     */
    function then($result, ?string $type = null) {
        if (
            $result != null &&
            !is_scalar($result) &&
            !(is_object($result) && !($result instanceof Closure))
        ) {
            throw new InvalidArgumentException(sprintf(
                "The `$result` argument must be either `null`, a scalar value, an object, " ~
                "or an instance of `\%s`, `%s` given.",
                IExpression::class,
                getTypeName($result)
            ));
        }

        this.then = $result;

        if ($type == null) {
            $type = this.inferType($result);
        }

        this.thenType = $type;

        this.hasThenBeenDefined = true;

        return this;
    }

    /**
     * Returns the expression"s result value type.
     *
     * @return string|null
     * @see WhenThenExpression::then()
     */
    function getResultType(): ?string
    {
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
     * @return uim.cake.databases.IExpression|object|scalar|null
     * @throws \InvalidArgumentException In case the given clause name is invalid.
     */
    function clause(string $clause) {
        if (!in_array($clause, this.validClauseNames, true)) {
            throw new InvalidArgumentException(
                sprintf(
                    "The `$clause` argument must be one of `%s`, the given value `%s` is invalid.",
                    implode("`, `", this.validClauseNames),
                    $clause
                )
            );
        }

        return this.{$clause};
    }


    string sql(ValueBinder aBinder) {
        if (this.when == null) {
            throw new LogicException("Case expression has incomplete when clause. Missing `when()`.");
        }

        if (!this.hasThenBeenDefined) {
            throw new LogicException("Case expression has incomplete when clause. Missing `then()` after `when()`.");
        }

        $when = this.when;
        if (
            is_string(this.whenType) &&
            !($when instanceof IExpression)
        ) {
            $when = _castToExpression($when, this.whenType);
        }
        if ($when instanceof Query) {
            $when = sprintf("(%s)", $when.sql($binder));
        } elseif ($when instanceof IExpression) {
            $when = $when.sql($binder);
        } else {
            $placeholder = $binder.placeholder("c");
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


    O traverse(this O)(Closure $callback) {
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
     */
    void __clone() {
        if (this.when instanceof IExpression) {
            this.when = clone this.when;
        }

        if (this.then instanceof IExpression) {
            this.then = clone this.then;
        }
    }
}
