module uim.cake.databases.Log;

import uim.cake.databases.statements.StatementDecorator;
use Exception;
use Psr\logs.LoggerInterface;

/**
 * Statement decorator used to
 *
 * @internal
 */
class LoggingStatement : StatementDecorator
{
    /**
     * Logger instance responsible for actually doing the logging task
     *
     * @var \Psr\logs.LoggerInterface
     */
    protected _logger;

    /**
     * Holds bound params
     *
     * @var array<array>
     */
    protected _compiledParams = [];

    /**
     * Query execution start time.
     *
     * @var float
     */
    protected $startTime = 0.0;

    /**
     * Logged query
     *
     * @var DDBlogs.LoggedQuery|null
     */
    protected $loggedQuery;

    /**
     * Wrapper for the execute function to calculate time spent
     * and log the query afterwards.
     *
     * @param array|null $params List of values to be bound to query
     * @return bool True on success, false otherwise
     * @throws \Exception Re-throws any exception raised during query execution.
     */
    bool execute(?array $params = null) {
        this.startTime = microtime(true);

        this.loggedQuery = new LoggedQuery();
        this.loggedQuery.driver = _driver;
        this.loggedQuery.params = $params ?: _compiledParams;

        try {
            $result = super.execute($params);
            this.loggedQuery.took = (int)round((microtime(true) - this.startTime) * 1000, 0);
        } catch (Exception $e) {
            /** @psalm-suppress UndefinedPropertyAssignment */
            $e.queryString = this.queryString;
            this.loggedQuery.error = $e;
            _log();
            throw $e;
        }

        if (preg_match("/^(?!SELECT)/i", this.queryString)) {
            this.rowCount();
        }

        return $result;
    }


    function fetch($type = self::FETCH_TYPE_NUM) {
        $record = super.fetch($type);

        if (this.loggedQuery) {
            this.rowCount();
        }

        return $record;
    }


    function fetchAll($type = self::FETCH_TYPE_NUM) {
        $results = super.fetchAll($type);

        if (this.loggedQuery) {
            this.rowCount();
        }

        return $results;
    }


    int rowCount() {
        $result = super.rowCount();

        if (this.loggedQuery) {
            this.loggedQuery.numRows = $result;
            _log();
        }

        return $result;
    }

    /**
     * Copies the logging data to the passed LoggedQuery and sends it
     * to the logging system.
     */
    protected void _log() {
        if (this.loggedQuery == null) {
            return;
        }

        this.loggedQuery.query = this.queryString;
        this.getLogger().debug((string)this.loggedQuery, ["query": this.loggedQuery]);

        this.loggedQuery = null;
    }

    /**
     * Wrapper for bindValue function to gather each parameter to be later used
     * in the logger function.
     *
     * @param string|int $column Name or param position to be bound
     * @param mixed $value The value to bind to variable in query
     * @param string|int|null $type PDO type or name of configured Type class
     */
    void bindValue($column, $value, $type = "string") {
        super.bindValue($column, $value, $type);

        if ($type == null) {
            $type = "string";
        }
        if (!ctype_digit($type)) {
            $value = this.cast($value, $type)[0];
        }
        _compiledParams[$column] = $value;
    }

    /**
     * Sets a logger
     *
     * @param \Psr\logs.LoggerInterface $logger Logger object
     */
    void setLogger(LoggerInterface $logger) {
        _logger = $logger;
    }

    /**
     * Gets the logger object
     *
     * @return \Psr\logs.LoggerInterface logger instance
     */
    function getLogger(): LoggerInterface
    {
        return _logger;
    }
}
