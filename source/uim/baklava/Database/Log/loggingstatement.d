module uim.baklava.databases.Log;

import uim.baklava.databases.Statement\StatementDecorator;
use Exception;
use Psr\Log\LoggerInterface;

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
     * @var \Psr\Log\LoggerInterface
     */
    protected $_logger;

    /**
     * Holds bound params
     *
     * @var array<array>
     */
    protected $_compiledParams = [];

    /**
     * Query execution start time.
     *
     * @var float
     */
    protected $startTime = 0.0;

    /**
     * Logged query
     *
     * @var \Cake\Database\Log\LoggedQuery|null
     */
    protected $loggedQuery;

    /**
     * Wrapper for the execute function to calculate time spent
     * and log the query afterwards.
     *
     * @param array|null myParams List of values to be bound to query
     * @return bool True on success, false otherwise
     * @throws \Exception Re-throws any exception raised during query execution.
     */
    bool execute(?array myParams = null) {
        this.startTime = microtime(true);

        this.loggedQuery = new LoggedQuery();
        this.loggedQuery.driver = this._driver;
        this.loggedQuery.params = myParams ?: this._compiledParams;

        try {
            myResult = super.execute(myParams);
            this.loggedQuery.took = (int)round((microtime(true) - this.startTime) * 1000, 0);
        } catch (Exception $e) {
            /** @psalm-suppress UndefinedPropertyAssignment */
            $e.queryString = this.queryString;
            this.loggedQuery.error = $e;
            this._log();
            throw $e;
        }

        if (preg_match('/^(?!SELECT)/i', this.queryString)) {
            this.rowCount();
        }

        return myResult;
    }


    function fetch(myType = self::FETCH_TYPE_NUM) {
        $record = super.fetch(myType);

        if (this.loggedQuery) {
            this.rowCount();
        }

        return $record;
    }


    function fetchAll(myType = self::FETCH_TYPE_NUM) {
        myResults = super.fetchAll(myType);

        if (this.loggedQuery) {
            this.rowCount();
        }

        return myResults;
    }


    function rowCount(): int
    {
        myResult = super.rowCount();

        if (this.loggedQuery) {
            this.loggedQuery.numRows = myResult;
            this._log();
        }

        return myResult;
    }

    /**
     * Copies the logging data to the passed LoggedQuery and sends it
     * to the logging system.
     *
     * @return void
     */
    protected auto _log(): void
    {
        if (this.loggedQuery === null) {
            return;
        }

        this.loggedQuery.query = this.queryString;
        this.getLogger().debug((string)this.loggedQuery, ['query' => this.loggedQuery]);

        this.loggedQuery = null;
    }

    /**
     * Wrapper for bindValue function to gather each parameter to be later used
     * in the logger function.
     *
     * @param string|int $column Name or param position to be bound
     * @param mixed myValue The value to bind to variable in query
     * @param string|int|null myType PDO type or name of configured Type class
     * @return void
     */
    function bindValue($column, myValue, myType = 'string'): void
    {
        super.bindValue($column, myValue, myType);

        if (myType === null) {
            myType = 'string';
        }
        if (!ctype_digit(myType)) {
            myValue = this.cast(myValue, myType)[0];
        }
        this._compiledParams[$column] = myValue;
    }

    /**
     * Sets a logger
     *
     * @param \Psr\Log\LoggerInterface $logger Logger object
     * @return void
     */
    auto setLogger(LoggerInterface $logger): void
    {
        this._logger = $logger;
    }

    /**
     * Gets the logger object
     *
     * @return \Psr\Log\LoggerInterface logger instance
     */
    auto getLogger(): LoggerInterface
    {
        return this._logger;
    }
}
