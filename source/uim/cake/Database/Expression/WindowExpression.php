


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Expression;

import uim.cake.databases.IExpression;
import uim.cake.databases.ValueBinder;
use Closure;

/**
 * This represents a SQL window expression used by aggregate and window functions.
 */
class WindowExpression : IExpression, WindowInterface
{
    /**
     * @var \Cake\Database\Expression\IdentifierExpression
     */
    protected $name;

    /**
     * @var array<\Cake\Database\IExpression>
     */
    protected $partitions = [];

    /**
     * @var \Cake\Database\Expression\OrderByExpression|null
     */
    protected $order;

    /**
     * @var array|null
     */
    protected $frame;

    /**
     * @var string|null
     */
    protected $exclusion;

    /**
     * @param string $name Window name
     */
    public this(string $name = "") {
        this.name = new IdentifierExpression($name);
    }

    /**
     * Return whether is only a named window expression.
     *
     * These window expressions only specify a named window and do not
     * specify their own partitions, frame or order.
     *
     * @return bool
     */
    function isNamedOnly(): bool
    {
        return this.name.getIdentifier() && (!this.partitions && !this.frame && !this.order);
    }

    /**
     * Sets the window name.
     *
     * @param string $name Window name
     * @return this
     */
    function name(string $name) {
        this.name = new IdentifierExpression($name);

        return this;
    }

    /**
     * @inheritDoc
     */
    function partition($partitions) {
        if (!$partitions) {
            return this;
        }

        if ($partitions instanceof Closure) {
            $partitions = $partitions(new QueryExpression([], [], ""));
        }

        if (!is_array($partitions)) {
            $partitions = [$partitions];
        }

        foreach ($partitions as &$partition) {
            if (is_string($partition)) {
                $partition = new IdentifierExpression($partition);
            }
        }

        this.partitions = array_merge(this.partitions, $partitions);

        return this;
    }

    /**
     * @inheritDoc
     */
    function order($fields) {
        if (!$fields) {
            return this;
        }

        if (this.order == null) {
            this.order = new OrderByExpression();
        }

        if ($fields instanceof Closure) {
            $fields = $fields(new QueryExpression([], [], ""));
        }

        this.order.add($fields);

        return this;
    }

    /**
     * @inheritDoc
     */
    function range($start, $end = 0) {
        return this.frame(self::RANGE, $start, self::PRECEDING, $end, self::FOLLOWING);
    }

    /**
     * @inheritDoc
     */
    function rows(?int $start, ?int $end = 0) {
        return this.frame(self::ROWS, $start, self::PRECEDING, $end, self::FOLLOWING);
    }

    /**
     * @inheritDoc
     */
    function groups(?int $start, ?int $end = 0) {
        return this.frame(self::GROUPS, $start, self::PRECEDING, $end, self::FOLLOWING);
    }

    /**
     * @inheritDoc
     */
    function frame(
        string $type,
        $startOffset,
        string $startDirection,
        $endOffset,
        string $endDirection
    ) {
        this.frame = [
            "type": $type,
            "start": [
                "offset": $startOffset,
                "direction": $startDirection,
            ],
            "end": [
                "offset": $endOffset,
                "direction": $endDirection,
            ],
        ];

        return this;
    }

    /**
     * @inheritDoc
     */
    function excludeCurrent() {
        this.exclusion = "CURRENT ROW";

        return this;
    }

    /**
     * @inheritDoc
     */
    function excludeGroup() {
        this.exclusion = "GROUP";

        return this;
    }

    /**
     * @inheritDoc
     */
    function excludeTies() {
        this.exclusion = "TIES";

        return this;
    }

    /**
     * @inheritDoc
     */
    function sql(ValueBinder $binder): string
    {
        $clauses = [];
        if (this.name.getIdentifier()) {
            $clauses[] = this.name.sql($binder);
        }

        if (this.partitions) {
            $expressions = [];
            foreach (this.partitions as $partition) {
                $expressions[] = $partition.sql($binder);
            }

            $clauses[] = "PARTITION BY " . implode(", ", $expressions);
        }

        if (this.order) {
            $clauses[] = this.order.sql($binder);
        }

        if (this.frame) {
            $start = this.buildOffsetSql(
                $binder,
                this.frame["start"]["offset"],
                this.frame["start"]["direction"]
            );
            $end = this.buildOffsetSql(
                $binder,
                this.frame["end"]["offset"],
                this.frame["end"]["direction"]
            );

            $frameSql = sprintf("%s BETWEEN %s AND %s", this.frame["type"], $start, $end);

            if (this.exclusion != null) {
                $frameSql .= " EXCLUDE " . this.exclusion;
            }

            $clauses[] = $frameSql;
        }

        return implode(" ", $clauses);
    }

    /**
     * @inheritDoc
     */
    public O traverse(this O)(Closure $callback) {
        $callback(this.name);
        foreach (this.partitions as $partition) {
            $callback($partition);
            $partition.traverse($callback);
        }

        if (this.order) {
            $callback(this.order);
            this.order.traverse($callback);
        }

        if (this.frame != null) {
            $offset = this.frame["start"]["offset"];
            if ($offset instanceof IExpression) {
                $callback($offset);
                $offset.traverse($callback);
            }
            $offset = this.frame["end"]["offset"] ?? null;
            if ($offset instanceof IExpression) {
                $callback($offset);
                $offset.traverse($callback);
            }
        }

        return this;
    }

    /**
     * Builds frame offset sql.
     *
     * @param \Cake\Database\ValueBinder $binder Value binder
     * @param \Cake\Database\IExpression|string|int|null $offset Frame offset
     * @param string $direction Frame offset direction
     * @return string
     */
    protected function buildOffsetSql(ValueBinder $binder, $offset, string $direction): string
    {
        if ($offset == 0) {
            return "CURRENT ROW";
        }

        if ($offset instanceof IExpression) {
            $offset = $offset.sql($binder);
        }

        return sprintf(
            "%s %s",
            $offset ?? "UNBOUNDED",
            $direction
        );
    }

    /**
     * Clone this object and its subtree of expressions.
     *
     * @return void
     */
    function __clone() {
        this.name = clone this.name;
        foreach (this.partitions as $i: $partition) {
            this.partitions[$i] = clone $partition;
        }
        if (this.order != null) {
            this.order = clone this.order;
        }
    }
}
