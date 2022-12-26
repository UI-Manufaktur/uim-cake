


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.cores.Retry;

use Exception;

/**
 * Used to instruct a CommandRetry object on whether a retry
 * for an action should be performed
 */
interface RetryStrategyInterface
{
    /**
     * Returns true if the action can be retried, false otherwise.
     *
     * @param \Exception $exception The exception that caused the action to fail
     * @param int $retryCount The number of times action has been retried
     * @return bool Whether it is OK to retry the action
     */
    function shouldRetry(Exception $exception, int $retryCount): bool;
}
