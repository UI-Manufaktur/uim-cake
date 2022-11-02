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
    protected myName;

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
     * @param string myName Window name
     */
    this(string myName = '') {
        this.name = new IdentifierExpression(myName);
    }

    /**
     * Return whether is only a named window expression.
     *
     * These window expressions only specify a named window and do not
     * specify their own partitions, frame or order.
    bool isNamedOnly() {
        return this.name.getIdentifier() && (!this.partitions && !this.frame && !this.order);
    }

    /**
     * Sets the window name.
     *
     * @param string myName Window name
     * @return this
     */
    function name(string myName) {
        this.name = new IdentifierExpression(myName);

        return this;
    }


    function partition($partitions) {
        if (!$partitions) {
            return this;
        }

        if ($partitions instanceof Closure) {
            $partitions = $partitions(new QueryExpression([], [], ''));
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


    function order(myFields) {
        if (!myFields) {
            return this;
        }

        if (this.order === null) {
            this.order = new OrderByExpression();
        }

        if (myFields instanceof Closure) {
            myFields = myFields(new QueryExpression([], [], ''));
        }

        this.order.add(myFields);

        return this;
    }


    function range($start, $end = 0) {
        return this.frame(self::RANGE, $start, self::PRECEDING, $end, self::FOLLOWING);
    }


    function rows(?int $start, ?int $end = 0) {
        return this.frame(self::ROWS, $start, self::PRECEDING, $end, self::FOLLOWING);
    }


    function groups(?int $start, ?int $end = 0) {
        return this.frame(self::GROUPS, $start, self::PRECEDING, $end, self::FOLLOWING);
    }


    function frame(
        string myType,
        $startOffset,
        string $startDirection,
        $endOffset,
        string $endDirection
    ) {
        this.frame = [
            'type' => myType,
            'start' => [
                'offset' => $startOffset,
                'direction' => $startDirection,
            ],
            'end' => [
                'offset' => $endOffset,
                'direction' => $endDirection,
            ],
        ];

        return this;
    }


    function excludeCurrent() {
        this.exclusion = 'CURRENT ROW';

        return this;
    }


    function excludeGroup() {
        this.exclusion = 'GROUP';

        return this;
    }


    function excludeTies() {
        this.exclusion = 'TIES';

        return this;
    }


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

            $clauses[] = 'PARTITION BY ' . implode(', ', $expressions);
        }

        if (this.order) {
            $clauses[] = this.order.sql($binder);
        }

        if (this.frame) {
            $start = this.buildOffsetSql(
                $binder,
                this.frame['start']['offset'],
                this.frame['start']['direction']
            );
            $end = this.buildOffsetSql(
                $binder,
                this.frame['end']['offset'],
                this.frame['end']['direction']
            );

            $frameSql = sprintf('%s BETWEEN %s AND %s', this.frame['type'], $start, $end);

            if (this.exclusion !== null) {
                $frameSql .= ' EXCLUDE ' . this.exclusion;
            }

            $clauses[] = $frameSql;
        }

        return implode(' ', $clauses);
    }


    function traverse(Closure $callback) {
        $callback(this.name);
        foreach (this.partitions as $partition) {
            $callback($partition);
            $partition.traverse($callback);
        }

        if (this.order) {
            $callback(this.order);
            this.order.traverse($callback);
        }

        if (this.frame !== null) {
            $offset = this.frame['start']['offset'];
            if ($offset instanceof IExpression) {
                $callback($offset);
                $offset.traverse($callback);
            }
            $offset = this.frame['end']['offset'] ?? null;
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
    protected auto buildOffsetSql(ValueBinder $binder, $offset, string $direction): string
    {
        if ($offset === 0) {
            return 'CURRENT ROW';
        }

        if ($offset instanceof IExpression) {
            $offset = $offset.sql($binder);
        }

        mySql = sprintf(
            '%s %s',
            $offset ?? 'UNBOUNDED',
            $direction
        );

        return mySql;
    }

    /**
     * Clone this object and its subtree of expressions.
     *
     * @return void
     */
    auto __clone() {
        this.name = clone this.name;
        foreach (this.partitions as $i => $partition) {
            this.partitions[$i] = clone $partition;
        }
        if (this.order !== null) {
            this.order = clone this.order;
        }
    }
}
