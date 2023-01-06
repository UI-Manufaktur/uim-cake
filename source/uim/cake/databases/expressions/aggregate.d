


 *


 * @since         4.1.0
  */module uim.cake.databases.Expression;

import uim.cake.databases.ValueBinder;
use Closure;

/**
 * This represents an SQL aggregate function expression in an SQL statement.
 * Calls can be constructed by passing the name of the function and a list of params.
 * For security reasons, all params passed are quoted by default unless
 * explicitly told otherwise.
 */
class AggregateExpression : FunctionExpression : IWindow
{
    /**
     * @var uim.cake.databases.Expression\QueryExpression
     */
    protected $filter;

    /**
     * @var uim.cake.databases.Expression\WindowExpression
     */
    protected $window;

    /**
     * Adds conditions to the FILTER clause. The conditions are the same format as
     * `Query::where()`.
     *
     * @param uim.cake.databases.IExpression|\Closure|array|string $conditions The conditions to filter on.
     * @param array<string, string> $types Associative array of type names used to bind values to query
     * @return this
     * @see uim.cake.databases.Query::where()
     */
    function filter($conditions, array $types = []) {
        if (this.filter == null) {
            this.filter = new QueryExpression();
        }

        if ($conditions instanceof Closure) {
            $conditions = $conditions(new QueryExpression());
        }

        this.filter.add($conditions, $types);

        return this;
    }

    /**
     * Adds an empty `OVER()` window expression or a named window epression.
     *
     * @param string|null $name Window name
     * @return this
     */
    function over(Nullable!string aName = null) {
        if (this.window == null) {
            this.window = new WindowExpression();
        }
        if ($name) {
            // Set name manually in case this was chained from FunctionsBuilder wrapper
            this.window.name($name);
        }

        return this;
    }


    function partition($partitions) {
        this.over();
        this.window.partition($partitions);

        return this;
    }


    function order($fields) {
        this.over();
        this.window.order($fields);

        return this;
    }


    function range($start, $end = 0) {
        this.over();
        this.window.range($start, $end);

        return this;
    }


    function rows(Nullable!int $start, Nullable!int $end = 0) {
        this.over();
        this.window.rows($start, $end);

        return this;
    }


    function groups(Nullable!int $start, Nullable!int $end = 0) {
        this.over();
        this.window.groups($start, $end);

        return this;
    }


    function frame(
        string $type,
        $startOffset,
        string $startDirection,
        $endOffset,
        string $endDirection
    ) {
        this.over();
        this.window.frame($type, $startOffset, $startDirection, $endOffset, $endDirection);

        return this;
    }


    function excludeCurrent() {
        this.over();
        this.window.excludeCurrent();

        return this;
    }


    function excludeGroup() {
        this.over();
        this.window.excludeGroup();

        return this;
    }


    function excludeTies() {
        this.over();
        this.window.excludeTies();

        return this;
    }


    string sql(ValueBinder aBinder) {
        $sql = super.sql(aBinder);
        if (this.filter != null) {
            $sql .= " FILTER (WHERE " ~ this.filter.sql(aBinder) ~ ")";
        }
        if (this.window != null) {
            if (this.window.isNamedOnly()) {
                $sql .= " OVER " ~ this.window.sql(aBinder);
            } else {
                $sql .= " OVER (" ~ this.window.sql(aBinder) ~ ")";
            }
        }

        return $sql;
    }


    O traverse(this O)(Closure $callback) {
        super.traverse($callback);
        if (this.filter != null) {
            $callback(this.filter);
            this.filter.traverse($callback);
        }
        if (this.window != null) {
            $callback(this.window);
            this.window.traverse($callback);
        }

        return this;
    }


    size_t count() {
        $count = super.count();
        if (this.window != null) {
            $count = $count + 1;
        }

        return $count;
    }

    // Clone this object and its subtree of expressions.
    void __clone() {
        super.__clone();
        if (this.filter != null) {
            this.filter = clone this.filter;
        }
        if (this.window != null) {
            this.window = clone this.window;
        }
    }
}
