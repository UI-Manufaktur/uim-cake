module uim.cake.databases.expressions;

import uim.cake.databases.ValueBinder;
use Closure;

/**
 * This represents an SQL aggregate function expression in an SQL statement.
 * Calls can be constructed by passing the name of the function and a list of params.
 * For security reasons, all params passed are quoted by default unless
 * explicitly told otherwise.
 */
class AggregateExpression : FunctionExpression : WindowInterface
{
    /**
     * @var \Cake\Database\Expression\QueryExpression
     */
    protected $filter;

    /**
     * @var \Cake\Database\Expression\WindowExpression
     */
    protected $window;

    /**
     * Adds conditions to the FILTER clause. The conditions are the same format as
     * `Query::where()`.
     *
     * @param \Cake\Database\IExpression|\Closure|array|string $conditions The conditions to filter on.
     * @param array<string, string> myTypes Associative array of type names used to bind values to query
     * @return this
     * @see \Cake\Database\Query::where()
     */
    function filter($conditions, array myTypes = []) {
        if (this.filter === null) {
            this.filter = new QueryExpression();
        }

        if ($conditions instanceof Closure) {
            $conditions = $conditions(new QueryExpression());
        }

        this.filter.add($conditions, myTypes);

        return this;
    }

    /**
     * Adds an empty `OVER()` window expression or a named window epression.
     *
     * @param string|null myName Window name
     * @return this
     */
    function over(?string myName = null) {
        if (this.window === null) {
            this.window = new WindowExpression();
        }
        if (myName) {
            // Set name manually in case this was chained from FunctionsBuilder wrapper
            this.window.name(myName);
        }

        return this;
    }


    function partition($partitions) {
        this.over();
        this.window.partition($partitions);

        return this;
    }


    function order(myFields) {
        this.over();
        this.window.order(myFields);

        return this;
    }


    function range($start, $end = 0) {
        this.over();
        this.window.range($start, $end);

        return this;
    }


    function rows(?int $start, ?int $end = 0) {
        this.over();
        this.window.rows($start, $end);

        return this;
    }


    function groups(?int $start, ?int $end = 0) {
        this.over();
        this.window.groups($start, $end);

        return this;
    }


    function frame(
        string myType,
        $startOffset,
        string $startDirection,
        $endOffset,
        string $endDirection
    ) {
        this.over();
        this.window.frame(myType, $startOffset, $startDirection, $endOffset, $endDirection);

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


    function sql(ValueBinder $binder): string
    {
        mySql = super.sql($binder);
        if (this.filter !== null) {
            mySql .= ' FILTER (WHERE ' . this.filter.sql($binder) . ')';
        }
        if (this.window !== null) {
            if (this.window.isNamedOnly()) {
                mySql .= ' OVER ' . this.window.sql($binder);
            } else {
                mySql .= ' OVER (' . this.window.sql($binder) . ')';
            }
        }

        return mySql;
    }


    function traverse(Closure $callback) {
        super.traverse($callback);
        if (this.filter !== null) {
            $callback(this.filter);
            this.filter.traverse($callback);
        }
        if (this.window !== null) {
            $callback(this.window);
            this.window.traverse($callback);
        }

        return this;
    }


    function count(): int
    {
        myCount = super.count();
        if (this.window !== null) {
            myCount = myCount + 1;
        }

        return myCount;
    }

    /**
     * Clone this object and its subtree of expressions.
     *
     * @return void
     */
    auto __clone() {
        super.__clone();
        if (this.filter !== null) {
            this.filter = clone this.filter;
        }
        if (this.window !== null) {
            this.window = clone this.window;
        }
    }
}
