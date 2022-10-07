

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.database.Expression;

import uim.cake.database.IExpression;
import uim.cake.database.ValueBinder;
use Closure;
use RuntimeException;

/**
 * An expression that represents a common table expression definition.
 */
class CommonTableExpression : IExpression
{
    /**
     * The CTE name.
     *
     * @var \Cake\Database\Expression\IdentifierExpression
     */
    protected myName;

    /**
     * The field names to use for the CTE.
     *
     * @var array<\Cake\Database\Expression\IdentifierExpression>
     */
    protected myFields = [];

    /**
     * The CTE query definition.
     *
     * @var \Cake\Database\IExpression|null
     */
    protected myQuery;

    /**
     * Whether the CTE is materialized or not materialized.
     *
     * @var string|null
     */
    protected $materialized = null;

    /**
     * Whether the CTE is recursive.
     *
     * @var bool
     */
    protected $recursive = false;

    /**
     * Constructor.
     *
     * @param string myName The CTE name.
     * @param \Cake\Database\IExpression|\Closure myQuery CTE query
     */
    this(string myName = '', myQuery = null)
    {
        this.name = new IdentifierExpression(myName);
        if (myQuery) {
            this.query(myQuery);
        }
    }

    /**
     * Sets the name of this CTE.
     *
     * This is the named you used to reference the expression
     * in select, insert, etc queries.
     *
     * @param string myName The CTE name.
     * @return this
     */
    function name(string myName)
    {
        this.name = new IdentifierExpression(myName);

        return this;
    }

    /**
     * Sets the query for this CTE.
     *
     * @param \Cake\Database\IExpression|\Closure myQuery CTE query
     * @return this
     */
    function query(myQuery)
    {
        if (myQuery instanceof Closure) {
            myQuery = myQuery();
            if (!(myQuery instanceof IExpression)) {
                throw new RuntimeException(
                    'You must return an `IExpression` from a Closure passed to `query()`.'
                );
            }
        }
        this.query = myQuery;

        return this;
    }

    /**
     * Adds one or more fields (arguments) to the CTE.
     *
     * @param \Cake\Database\Expression\IdentifierExpression|array<\Cake\Database\Expression\IdentifierExpression>|array<string>|string myFields Field names
     * @return this
     */
    function field(myFields)
    {
        myFields = (array)myFields;
        foreach (myFields as &myField) {
            if (!(myField instanceof IdentifierExpression)) {
                myField = new IdentifierExpression(myField);
            }
        }
        this.fields = array_merge(this.fields, myFields);

        return this;
    }

    /**
     * Sets this CTE as materialized.
     *
     * @return this
     */
    function materialized() {
        this.materialized = 'MATERIALIZED';

        return this;
    }

    /**
     * Sets this CTE as not materialized.
     *
     * @return this
     */
    function notMaterialized() {
        this.materialized = 'NOT MATERIALIZED';

        return this;
    }

    /**
     * Gets whether this CTE is recursive.
     *
     * @return bool
     */
    function isRecursive(): bool
    {
        return this.recursive;
    }

    /**
     * Sets this CTE as recursive.
     *
     * @return this
     */
    function recursive() {
        this.recursive = true;

        return this;
    }


    function sql(ValueBinder $binder): string
    {
        myFields = '';
        if (this.fields) {
            $expressions = array_map(function (IdentifierExpression $e) use ($binder) {
                return $e.sql($binder);
            }, this.fields);
            myFields = sprintf('(%s)', implode(', ', $expressions));
        }

        $suffix = this.materialized ? this.materialized . ' ' : '';

        return sprintf(
            '%s%s AS %s(%s)',
            this.name.sql($binder),
            myFields,
            $suffix,
            this.query ? this.query.sql($binder) : ''
        );
    }


    function traverse(Closure $callback)
    {
        $callback(this.name);
        foreach (this.fields as myField) {
            $callback(myField);
            myField.traverse($callback);
        }

        if (this.query) {
            $callback(this.query);
            this.query.traverse($callback);
        }

        return this;
    }

    /**
     * Clones the inner expression objects.
     *
     * @return void
     */
    auto __clone() {
        this.name = clone this.name;
        if (this.query) {
            this.query = clone this.query;
        }

        foreach (this.fields as myKey => myField) {
            this.fields[myKey] = clone myField;
        }
    }
}
