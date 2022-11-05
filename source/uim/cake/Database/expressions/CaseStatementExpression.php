

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.databases.expressions;

import uim.cake.databases.IExpression;
import uim.cake.databases.Type\ExpressionTypeCasterTrait;
import uim.cake.databases.TypedResultInterface;
import uim.cake.databases.TypeMapTrait;
import uim.cake.databases.ValueBinder;
use Closure;
use InvalidArgumentException;
use LogicException;

/**
 * Represents a SQL case statement with a fluid API
 */
class CaseStatementExpression : IExpression, TypedResultInterface
{
    use CaseExpressionTrait;
    use ExpressionTypeCasterTrait;
    use TypeMapTrait;

    /**
     * The names of the clauses that are valid for use with the
     * `clause()` method.
     *
     * @var array<string>
     */
    protected $validClauseNames = [
        'value',
        'when',
        'else',
    ];

    /**
     * Whether this is a simple case expression.
     *
     * @var bool
     */
    protected $isSimpleVariant = false;

    /**
     * The case value.
     *
     * @var \Cake\Database\IExpression|object|scalar|null
     */
    protected myValue = null;

    /**
     * The case value type.
     *
     * @var string|null
     */
    protected myValueType = null;

    /**
     * The `WHEN ... THEN ...` expressions.
     *
     * @var array<\Cake\Database\Expression\WhenThenExpression>
     */
    protected $when = [];

    /**
     * Buffer that holds values and types for use with `then()`.
     *
     * @var array|null
     */
    protected $whenBuffer = null;

    /**
     * The else part result value.
     *
     * @var \Cake\Database\IExpression|object|scalar|null
     */
    protected $else = null;

    /**
     * The else part result type.
     *
     * @var string|null
     */
    protected $elseType = null;

    /**
     * The return type.
     *
     * @var string|null
     */
    protected $returnType = null;

    /**
     * Constructor.
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
     */
    this(myValue = null, ?string myType = null) {
        if (func_num_args() > 0) {
            if (
                myValue !== null &&
                !is_scalar(myValue) &&
                !(is_object(myValue) && !(myValue instanceof Closure))
            ) {
                throw new InvalidArgumentException(sprintf(
                    'The `myValue` argument must be either `null`, a scalar value, an object, ' .
                    'or an instance of `\%s`, `%s` given.',
                    IExpression::class,
                    getTypeName(myValue)
                ));
            }

            this.value = myValue;

            if (
                myValue !== null &&
                myType === null &&
                !(myValue instanceof IExpression)
            ) {
                myType = this.inferType(myValue);
            }
            this.valueType = myType;

            this.isSimpleVariant = true;
        }
    }

    /**
     * Sets the `WHEN` value for a `WHEN ... THEN ...` expression, or a
     * self-contained expression that holds both the value for `WHEN`
     * and the value for `THEN`.
     *
     * ### Order based syntax
     *
     * When passing a value other than a self-contained
     * `\Cake\Database\Expression\WhenThenExpression`,
     * instance, the `WHEN ... THEN ...` statement must be closed off with
     * a call to `then()` before invoking `when()` again or `else()`:
     *
     * ```
     * myQueryExpression
     *     .case(myQuery.identifier('Table.column'))
     *     .when(true)
     *     .then('Yes')
     *     .when(false)
     *     .then('No')
     *     .else('Maybe');
     * ```
     *
     * ### Self-contained expressions
     *
     * When passing an instance of `\Cake\Database\Expression\WhenThenExpression`,
     * being it directly, or via a callable, then there is no need to close
     * using `then()` on this object, instead the statement will be closed
     * on the `\Cake\Database\Expression\WhenThenExpression`
     * object using
     * `\Cake\Database\Expression\WhenThenExpression::then()`.
     *
     * Callables will receive an instance of `\Cake\Database\Expression\WhenThenExpression`,
     * and must return one, being it the same object, or a custom one:
     *
     * ```
     * myQueryExpression
     *     .case()
     *     .when(function (\Cake\Database\Expression\WhenThenExpression $whenThen) {
     *         return $whenThen
     *             .when(['Table.column' => true])
     *             .then('Yes');
     *     })
     *     .when(function (\Cake\Database\Expression\WhenThenExpression $whenThen) {
     *         return $whenThen
     *             .when(['Table.column' => false])
     *             .then('No');
     *     })
     *     .else('Maybe');
     * ```
     *
     * ### Type handling
     *
     * The types provided via the `myType` argument will be merged with the
     * type map set for this expression. When using callables for `$when`,
     * the `\Cake\Database\Expression\WhenThenExpression`
     * instance received by the callables will inherit that type map, however
     * the types passed here will _not_ be merged in case of using callables,
     * instead the types must be passed in
     * `\Cake\Database\Expression\WhenThenExpression::when()`:
     *
     * ```
     * myQueryExpression
     *     .case()
     *     .when(function (\Cake\Database\Expression\WhenThenExpression $whenThen) {
     *         return $whenThen
     *             .when(['unmapped_column' => true], ['unmapped_column' => 'bool'])
     *             .then('Yes');
     *     })
     *     .when(function (\Cake\Database\Expression\WhenThenExpression $whenThen) {
     *         return $whenThen
     *             .when(['unmapped_column' => false], ['unmapped_column' => 'bool'])
     *             .then('No');
     *     })
     *     .else('Maybe');
     * ```
     *
     * ### User data safety
     *
     * When passing user data, be aware that allowing a user defined array
     * to be passed, is a potential SQL injection vulnerability, as it
     * allows for raw SQL to slip in!
     *
     * The following is _unsafe_ usage that must be avoided:
     *
     * ```
     * $case
     *      .when(myUserData)
     * ```
     *
     * A safe variant for the above would be to define a single type for
     * the value:
     *
     * ```
     * $case
     *      .when(myUserData, 'integer')
     * ```
     *
     * This way an exception would be triggered when an array is passed for
     * the value, thus preventing raw SQL from slipping in, and all other
     * types of values would be forced to be bound as an integer.
     *
     * Another way to safely pass user data is when using a conditions
     * array, and passing user data only on the value side of the array
     * entries, which will cause them to be bound:
     *
     * ```
     * $case
     *      .when([
     *          'Table.column' => myUserData,
     *      ])
     * ```
     *
     * Lastly, data can also be bound manually:
     *
     * ```
     * myQuery
     *      .select([
     *          'val' => myQuery.newExpr()
     *              .case()
     *              .when(myQuery.newExpr(':userData'))
     *              .then(123)
     *      ])
     *      .bind(':userData', myUserData, 'integer')
     * ```
     *
     * @param \Cake\Database\IExpression|\Closure|object|array|scalar $when The `WHEN` value. When using an
     *  array of conditions, it must be compatible with `\Cake\Database\Query::where()`. Note that this argument is
     *  _not_ completely safe for use with user data, as a user supplied array would allow for raw SQL to slip in! If
     *  you plan to use user data, either pass a single type for the `myType` argument (which forces the `$when` value to
     *  be a non-array, and then always binds the data), use a conditions array where the user data is only passed on
     *  the value side of the array entries, or custom bindings!
     * @param array<string, string>|string|null myType The when value type. Either an associative array when using array style
     *  conditions, or else a string. If no type is provided, the type will be tried to be inferred from the value.
     * @return this
     * @throws \LogicException In case this a closing `then()` call is required before calling this method.
     * @throws \LogicException In case the callable doesn't return an instance of
     *  `\Cake\Database\Expression\WhenThenExpression`.
     */
    function when($when, myType = null) {
        if (this.whenBuffer !== null) {
            throw new LogicException('Cannot call `when()` between `when()` and `then()`.');
        }

        if ($when instanceof Closure) {
            $when = $when(new WhenThenExpression(this.getTypeMap()));
            if (!($when instanceof WhenThenExpression)) {
                throw new LogicException(sprintf(
                    '`when()` callables must return an instance of `\%s`, `%s` given.',
                    WhenThenExpression::class,
                    getTypeName($when)
                ));
            }
        }

        if ($when instanceof WhenThenExpression) {
            this.when[] = $when;
        } else {
            this.whenBuffer = ['when' => $when, 'type' => myType];
        }

        return this;
    }

    /**
     * Sets the `THEN` result value for the last `WHEN ... THEN ...`
     * statement that was opened using `when()`.
     *
     * ### Order based syntax
     *
     * This method can only be invoked in case `when()` was previously
     * used with a value other than a closure or an instance of
     * `\Cake\Database\Expression\WhenThenExpression`:
     *
     * ```
     * $case
     *     .when(['Table.column' => true])
     *     .then('Yes')
     *     .when(['Table.column' => false])
     *     .then('No')
     *     .else('Maybe');
     * ```
     *
     * The following would all fail with an exception:
     *
     * ```
     * $case
     *     .when(['Table.column' => true])
     *     .when(['Table.column' => false])
     *     // ...
     * ```
     *
     * ```
     * $case
     *     .when(['Table.column' => true])
     *     .else('Maybe')
     *     // ...
     * ```
     *
     * ```
     * $case
     *     .then('Yes')
     *     // ...
     * ```
     *
     * ```
     * $case
     *     .when(['Table.column' => true])
     *     .then('Yes')
     *     .then('No')
     *     // ...
     * ```
     *
     * @param \Cake\Database\IExpression|object|scalar|null myResult The result value.
     * @param string|null myType The result type. If no type is provided, the type will be tried to be inferred from the
     *  value.
     * @return this
     * @throws \LogicException In case `when()` wasn't previously called with a value other than a closure or an
     *  instance of `\Cake\Database\Expression\WhenThenExpression`.
     */
    function then(myResult, ?string myType = null) {
        if (this.whenBuffer === null) {
            throw new LogicException('Cannot call `then()` before `when()`.');
        }

        $whenThen = (new WhenThenExpression(this.getTypeMap()))
            .when(this.whenBuffer['when'], this.whenBuffer['type'])
            .then(myResult, myType);

        this.whenBuffer = null;

        this.when[] = $whenThen;

        return this;
    }

    /**
     * Sets the `ELSE` result value.
     *
     * @param \Cake\Database\IExpression|object|scalar|null myResult The result value.
     * @param string|null myType The result type. If no type is provided, the type will be tried to be inferred from the
     *  value.
     * @return this
     * @throws \LogicException In case a closing `then()` call is required before calling this method.
     * @throws \InvalidArgumentException In case the `myResult` argument is neither a scalar value, nor an object, an
     *  instance of `\Cake\Database\IExpression`, or `null`.
     */
    function else(myResult, ?string myType = null) {
        if (this.whenBuffer !== null) {
            throw new LogicException('Cannot call `else()` between `when()` and `then()`.');
        }

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

        if (myType === null) {
            myType = this.inferType(myResult);
        }

        this.else = myResult;
        this.elseType = myType;

        return this;
    }

    /**
     * Returns the abstract type that this expression will return.
     *
     * If no type has been explicitly set via `setReturnType()`, this
     * method will try to obtain the type from the result types of the
     * `then()` and `else() `calls. All types must be identical in order
     * for this to work, otherwise the type will default to `string`.
     *
     * @return string
     * @see CaseStatementExpression::then()
     */
    auto getReturnType(): string
    {
        if (this.returnType !== null) {
            return this.returnType;
        }

        myTypes = [];
        foreach (this.when as $when) {
            myType = $when.getResultType();
            if (myType !== null) {
                myTypes[] = myType;
            }
        }

        if (this.elseType !== null) {
            myTypes[] = this.elseType;
        }

        myTypes = array_unique(myTypes);
        if (count(myTypes) === 1) {
            return myTypes[0];
        }

        return 'string';
    }

    /**
     * Sets the abstract type that this expression will return.
     *
     * If no type is being explicitly set via this method, then the
     * `getReturnType()` method will try to infer the type from the
     * result types of the `then()` and `else() `calls.
     *
     * @param string myType The type name to use.
     * @return this
     */
    auto setReturnType(string myType) {
        this.returnType = myType;

        return this;
    }

    /**
     * Returns the available data for the given clause.
     *
     * ### Available clauses
     *
     * The following clause names are available:
     *
     * * `value`: The case value for a `CASE case_value WHEN ...` expression.
     * * `when`: An array of `WHEN ... THEN ...` expressions.
     * * `else`: The `ELSE` result value.
     *
     * @param string $clause The name of the clause to obtain.
     * @return \Cake\Database\IExpression|object|array<\Cake\Database\Expression\WhenThenExpression>|scalar|null
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
        if (this.whenBuffer !== null) {
            throw new LogicException('Case expression has incomplete when clause. Missing `then()` after `when()`.');
        }

        if (empty(this.when)) {
            throw new LogicException('Case expression must have at least one when statement.');
        }

        myValue = '';
        if (this.isSimpleVariant) {
            myValue = this.compileNullableValue($binder, this.value, this.valueType) . ' ';
        }

        $whenThenExpressions = [];
        foreach (this.when as $whenThen) {
            $whenThenExpressions[] = $whenThen.sql($binder);
        }
        $whenThen = implode(' ', $whenThenExpressions);

        $else = this.compileNullableValue($binder, this.else, this.elseType);

        return "CASE {myValue}{$whenThen} ELSE $else END";
    }


    function traverse(Closure $callback) {
        if (this.whenBuffer !== null) {
            throw new LogicException('Case expression has incomplete when clause. Missing `then()` after `when()`.');
        }

        if (this.value instanceof IExpression) {
            $callback(this.value);
            this.value.traverse($callback);
        }

        foreach (this.when as $when) {
            $callback($when);
            $when.traverse($callback);
        }

        if (this.else instanceof IExpression) {
            $callback(this.else);
            this.else.traverse($callback);
        }

        return this;
    }

    /**
     * Clones the inner expression objects.
     *
     * @return void
     */
    auto __clone() {
        if (this.whenBuffer !== null) {
            throw new LogicException('Case expression has incomplete when clause. Missing `then()` after `when()`.');
        }

        if (this.value instanceof IExpression) {
            this.value = clone this.value;
        }

        foreach (this.when as myKey => $when) {
            this.when[myKey] = clone this.when[myKey];
        }

        if (this.else instanceof IExpression) {
            this.else = clone this.else;
        }
    }
}