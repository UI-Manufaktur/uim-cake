


 *


 * @since         4.1.0
  */
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
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
     * @var uim.cake.Database\Expression\IdentifierExpression
     */
    protected $name;

    /**
     * The field names to use for the CTE.
     *
     * @var array<uim.cake.Database\Expression\IdentifierExpression>
     */
    protected $fields = [];

    /**
     * The CTE query definition.
     *
     * @var uim.cake.Database\IExpression|null
     */
    protected $query;

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
     * @param string $name The CTE name.
     * @param uim.cake.Database\IExpression|\Closure $query CTE query
     */
    this(string $name = "", $query = null) {
        this.name = new IdentifierExpression($name);
        if ($query) {
            this.query($query);
        }
    }

    /**
     * Sets the name of this CTE.
     *
     * This is the named you used to reference the expression
     * in select, insert, etc queries.
     *
     * @param string $name The CTE name.
     * @return this
     */
    function name(string $name) {
        this.name = new IdentifierExpression($name);

        return this;
    }

    /**
     * Sets the query for this CTE.
     *
     * @param uim.cake.Database\IExpression|\Closure $query CTE query
     * @return this
     */
    function query($query) {
        if ($query instanceof Closure) {
            $query = $query();
            if (!($query instanceof IExpression)) {
                throw new RuntimeException(
                    "You must return an `IExpression` from a Closure passed to `query()`."
                );
            }
        }
        this.query = $query;

        return this;
    }

    /**
     * Adds one or more fields (arguments) to the CTE.
     *
     * @param uim.cake.Database\Expression\IdentifierExpression|array<uim.cake.Database\Expression\IdentifierExpression>|array<string>|string $fields Field names
     * @return this
     */
    function field($fields) {
        $fields = (array)$fields;
        foreach ($fields as &$field) {
            if (!($field instanceof IdentifierExpression)) {
                $field = new IdentifierExpression($field);
            }
        }
        this.fields = array_merge(this.fields, $fields);

        return this;
    }

    /**
     * Sets this CTE as materialized.
     *
     * @return this
     */
    function materialized() {
        this.materialized = "MATERIALIZED";

        return this;
    }

    /**
     * Sets this CTE as not materialized.
     *
     * @return this
     */
    function notMaterialized() {
        this.materialized = "NOT MATERIALIZED";

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
        $fields = "";
        if (this.fields) {
            $expressions = array_map(function (IdentifierExpression $e) use ($binder) {
                return $e.sql($binder);
            }, this.fields);
            $fields = sprintf("(%s)", implode(", ", $expressions));
        }

        $suffix = this.materialized ? this.materialized . " " : "";

        return sprintf(
            "%s%s AS %s(%s)",
            this.name.sql($binder),
            $fields,
            $suffix,
            this.query ? this.query.sql($binder) : ""
        );
    }


    O traverse(this O)(Closure $callback) {
        $callback(this.name);
        foreach (this.fields as $field) {
            $callback($field);
            $field.traverse($callback);
        }

        if (this.query) {
            $callback(this.query);
            this.query.traverse($callback);
        }

        return this;
    }

    /**
     * Clones the inner expression objects.
     */
    void __clone() {
        this.name = clone this.name;
        if (this.query) {
            this.query = clone this.query;
        }

        foreach (this.fields as $key: $field) {
            this.fields[$key] = clone $field;
        }
    }
}
