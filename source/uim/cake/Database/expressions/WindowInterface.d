module uim.cake.databases.expressions;

/**
 * This defines the functions used for building window expressions.
 */
interface WindowInterface
{
    /**
     * @var string
     */
    public const PRECEDING = 'PRECEDING';

    /**
     * @var string
     */
    public const FOLLOWING = 'FOLLOWING';

    /**
     * @var string
     */
    public const RANGE = 'RANGE';

    /**
     * @var string
     */
    public const ROWS = 'ROWS';

    /**
     * @var string
     */
    public const GROUPS = 'GROUPS';

    /**
     * Adds one or more partition expressions to the window.
     *
     * @param \Cake\Database\IExpression|\Closure|array<\Cake\Database\IExpression|string>|string $partitions Partition expressions
     * @return this
     */
    function partition($partitions);

    /**
     * Adds one or more order clauses to the window.
     *
     * @param \Cake\Database\IExpression|\Closure|array<\Cake\Database\IExpression|string>|string myFields Order expressions
     * @return this
     */
    function order(myFields);

    /**
     * Adds a simple range frame to the window.
     *
     * `$start`:
     *  - `0` - 'CURRENT ROW'
     *  - `null` - 'UNBOUNDED PRECEDING'
     *  - offset - 'offset PRECEDING'
     *
     * `$end`:
     *  - `0` - 'CURRENT ROW'
     *  - `null` - 'UNBOUNDED FOLLOWING'
     *  - offset - 'offset FOLLOWING'
     *
     * If you need to use 'FOLLOWING' with frame start or
     * 'PRECEDING' with frame end, use `frame()` instead.
     *
     * @param \Cake\Database\IExpression|string|int|null $start Frame start
     * @param \Cake\Database\IExpression|string|int|null $end Frame end
     *  If not passed in, only frame start SQL will be generated.
     * @return this
     */
    function range($start, $end = 0);

    /**
     * Adds a simple rows frame to the window.
     *
     * See `range()` for details.
     *
     * @param int|null $start Frame start
     * @param int|null $end Frame end
     *  If not passed in, only frame start SQL will be generated.
     * @return this
     */
    function rows(?int $start, ?int $end = 0);

    /**
     * Adds a simple groups frame to the window.
     *
     * See `range()` for details.
     *
     * @param int|null $start Frame start
     * @param int|null $end Frame end
     *  If not passed in, only frame start SQL will be generated.
     * @return this
     */
    function groups(?int $start, ?int $end = 0);

    /**
     * Adds a frame to the window.
     *
     * Use the `range()`, `rows()` or `groups()` helpers if you need simple
     * 'BETWEEN offset PRECEDING and offset FOLLOWING' frames.
     *
     * You can specify any direction for both frame start and frame end.
     *
     * With both `$startOffset` and `$endOffset`:
     *  - `0` - 'CURRENT ROW'
     *  - `null` - 'UNBOUNDED'
     *
     * @param string myType Frame type
     * @param \Cake\Database\IExpression|string|int|null $startOffset Frame start offset
     * @param string $startDirection Frame start direction
     * @param \Cake\Database\IExpression|string|int|null $endOffset Frame end offset
     * @param string $endDirection Frame end direction
     * @return this
     * @throws \InvalidArgumentException WHen offsets are negative.
     * @psalm-param self::RANGE|self::ROWS|self::GROUPS myType
     * @psalm-param self::PRECEDING|self::FOLLOWING $startDirection
     * @psalm-param self::PRECEDING|self::FOLLOWING $endDirection
     */
    function frame(
        string myType,
        $startOffset,
        string $startDirection,
        $endOffset,
        string $endDirection
    );

    /**
     * Adds current row frame exclusion.
     *
     * @return this
     */
    function excludeCurrent();

    /**
     * Adds group frame exclusion.
     *
     * @return this
     */
    function excludeGroup();

    /**
     * Adds ties frame exclusion.
     *
     * @return this
     */
    function excludeTies();
}
