module uim.baklava.databases.Log;

import uim.baklava.databases.Driver\Sqlserver;
use JsonSerializable;

/**
 * Contains a query string, the params used to executed it, time taken to do it
 * and the number of rows found or affected by its execution.
 *
 * @internal
 */
class LoggedQuery : JsonSerializable
{
    /**
     * Driver executing the query
     *
     * @var \Cake\Database\IDriver|null
     */
    public myDriver = null;

    /**
     * Query string that was executed
     *
     * @var string
     */
    public myQuery = '';

    /**
     * Number of milliseconds this query took to complete
     *
     * @var float
     */
    public $took = 0;



    /**
     * Number of rows affected or returned by the query execution
     *
     * @var int
     */
    public $numRows = 0;

    /**
     * The exception that was thrown by the execution of this query
     *
     * @var \Exception|null
     */
    public myError;

    /**
     * Helper function used to replace query placeholders by the real
     * params used to execute the query
     *
     * @return string
     */

    /* Associative array with the params bound to the query string */
    public STRINGAA myParams;
    protected string interpolate() {
        myParams = array_map(function ($p) {
            if ($p === null) {
                return 'NULL';
            }

            if (is_bool($p)) {
                if (this.driver instanceof Sqlserver) {
                    return $p ? '1' : '0';
                }

                return $p ? 'TRUE' : 'FALSE';
            }

            if (is_string($p)) {
                // Likely binary data like a blob or binary uuid.
                // pattern matches ascii control chars.
                if (preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/u', '', $p) !== $p) {
                    $p = bin2hex($p);
                }

                $replacements = [
                    '$' => '\\$',
                    '\\' => '\\\\\\\\',
                    "'" => "''",
                ];

                $p = strtr($p, $replacements);

                return "'$p'";
            }

            return $p;
        }, this.params);

        myKeys = [];
        $limit = is_int(key(myParams)) ? 1 : -1;
        foreach (myParams as myKey => $param) {
            myKeys[] = is_string(myKey) ? "/:myKey\b/" : '/[?]/';
        }

        return preg_replace(myKeys, myParams, this.query, $limit);
    }

    /**
     * Get the logging context data for a query.
     *
     * @return array<string, mixed>
     */
    auto getContext(): array
    {
        return [
            'numRows' => this.numRows,
            'took' => this.took,
        ];
    }

    /**
     * Returns data that will be serialized as JSON
     *
     * @return array<string, mixed>
     */
    function jsonSerialize(): array
    {
        myError = this.error;
        if (myError !== null) {
            myError = [
                'class' => get_class(myError),
                'message' => myError.getMessage(),
                'code' => myError.getCode(),
            ];
        }

        return [
            'query' => this.query,
            'numRows' => this.numRows,
            'params' => this.params,
            'took' => this.took,
            'error' => myError,
        ];
    }

    /**
     * Returns the string representation of this logged query
     *
     * @return string
     */
    auto __toString(): string
    {
        mySql = this.query;
        if (!empty(this.params)) {
            mySql = this.interpolate();
        }

        return mySql;
    }
}
