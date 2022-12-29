


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Retry;

import uim.cake.cores.Retry\RetryStrategyInterface;
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
     * @var int
     */
    protected $retryInterval;

    /**
     * @param array<int> $errorCodes DB-specific error codes that allow retrying
     * @param int $retryInterval Seconds to wait before allowing next retry, 0 for no wait.
     */
    public this(array $errorCodes, int $retryInterval) {
        this.errorCodes = $errorCodes;
        this.retryInterval = $retryInterval;
    }


    function shouldRetry(Exception $exception, int $retryCount): bool
    {
        if (
            $exception instanceof PDOException &&
            $exception.errorInfo &&
            in_array($exception.errorInfo[1], this.errorCodes)
        ) {
            if (this.retryInterval > 0) {
                sleep(this.retryInterval);
            }

            return true;
        }

        return false;
    }
}
