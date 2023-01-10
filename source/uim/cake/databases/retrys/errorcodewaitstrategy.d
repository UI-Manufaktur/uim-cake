


 *


 * @since         4.2.0
  */module uim.cake.databases.Retry;

import uim.cake.core.Retry\RetryStrategyInterface;
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
    protected $errorCodes;

    /**
     */
    protected int $retryInterval;

    /**
     * @param array<int> $errorCodes DB-specific error codes that allow retrying
     * @param int $retryInterval Seconds to wait before allowing next retry, 0 for no wait.
     */
    this(array $errorCodes, int $retryInterval) {
        this.errorCodes = $errorCodes;
        this.retryInterval = $retryInterval;
    }


    bool shouldRetry(Exception $exception, int $retryCount) {
        if (
            $exception instanceof PDOException &&
            $exception.errorInfo &&
            hasAllValues($exception.errorInfo[1], this.errorCodes)
        ) {
            if (this.retryInterval > 0) {
                sleep(this.retryInterval);
            }

            return true;
        }

        return false;
    }
}
