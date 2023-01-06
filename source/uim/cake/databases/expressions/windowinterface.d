module uim.cake.databases.Expression;

// This defines the functions used for building window expressions.
interface IWindow {
    /**
     */
    const string PRECEDING = "PRECEDING";

    /**
     */
    const string FOLLOWING = "FOLLOWING";

    /**
     */
    const string RANGE = "RANGE";

    /**
     */
    const string ROWS = "ROWS";

    /**
     */
    const string GROUPS = "GROUPS";

    /**
     * Adds one or more partition expressions to the window.
     *
     * @param uim.cake.databases.IExpression|\Closure|array<uim.cake.databases.IExpression|string>|string $partitions Partition expressions
     * @return this
     */
    function partition($partitions);

    /**
     * Adds one or more order clauses to the window.
     *
     * @param uim.cake.databases.IExpression|\Closure|array<uim.cake.databases.IExpression|string>|string $fields Order expressions
     * @return this
     */
    function order($fields);

    /**
     * Adds a simple range frame to the window.
     *
     * `$start`:
     *  - `0` - "CURRENT ROW"
     *  - `null` - "UNBOUNDED PRECEDING"
     *  - offset - "offset PRECEDING"
     *
     * `$end`:
     *  - `0` - "CURRENT ROW"
     *  - `null` - "UNBOUNDED FOLLOWING"
     *  - offset - "offset FOLLOWING"
     *
     * If you need to use "FOLLOWING" with frame start or
     * "PRECEDING" with frame end, use `frame()` instead.
     *
     * @param uim.cake.databases.IExpression|string|int|null $start Frame start
     * @param uim.cake.databases.IExpression|string|int|null $end Frame end
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
    function rows(Nullable!int $start, Nullable!int $end = 0);

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
    function groups(Nullable!int $start, Nullable!int $end = 0);

    /**
     * Adds a frame to the window.
     *
     * Use the `range()`, `rows()` or `groups()` helpers if you need simple
     * "BETWEEN offset PRECEDING and offset FOLLOWING" frames.
     *
     * You can specify any direction for both frame start and frame end.
     *
     * With both `$startOffset` and `$endOffset`:
     *  - `0` - "CURRENT ROW"
     *  - `null` - "UNBOUNDED"
     *
     * @param string $type Frame type
     * @param uim.cake.databases.IExpression|string|int|null $startOffset Frame start offset
     * @param string $startDirection Frame start direction
     * @param uim.cake.databases.IExpression|string|int|null $endOffset Frame end offset
     * @param string $endDirection Frame end direction
     * @return this
     * @throws \InvalidArgumentException WHen offsets are negative.
     * @psalm-param self::RANGE|self::ROWS|self::GROUPS $type
     * @psalm-param self::PRECEDING|self::FOLLOWING $startDirection
     * @psalm-param self::PRECEDING|self::FOLLOWING $endDirection
     */
    function frame(
        string $type,
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
