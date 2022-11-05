module uim.baklava.databases.Retry;

import uim.baklava.core.Retry\RetryStrategyInterface;
use Exception;
use PDOException;

/**
 * : retry strategy based on db error codes and wait interval.
 *
 * @internal
 */
class ErrorCodeWaitStrategy : RetryStrategyInterface
{
    /**
     * @var array<int>
     */
    protected myErrorCodes;

    /**
     * @var int
     */
    protected $retryInterval;

    /**
     * @param array<int> myErrorCodes DB-specific error codes that allow retrying
     * @param int $retryInterval Seconds to wait before allowing next retry, 0 for no wait.
     */
    this(array myErrorCodes, int $retryInterval) {
        this.errorCodes = myErrorCodes;
        this.retryInterval = $retryInterval;
    }


    bool shouldRetry(Exception myException, int $retryCount) {
        if (
            myException instanceof PDOException &&
            myException.errorInfo &&
            in_array(myException.errorInfo[1], this.errorCodes)
        ) {
            if (this.retryInterval > 0) {
                sleep(this.retryInterval);
            }

            return true;
        }

        return false;
    }
}
