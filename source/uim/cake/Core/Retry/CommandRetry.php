


 *


 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.core.Retry;

use Exception;

/**
 * Allows any action to be retried in case of an exception.
 *
 * This class can be parametrized with a strategy, which will be followed
 * to determine whether the action should be retried.
 */
class CommandRetry
{
    /**
     * The strategy to follow should the executed action fail.
     *
     * @var uim.cake.Core\Retry\RetryStrategyInterface
     */
    protected $strategy;

    /**
     * @var int
     */
    protected $maxRetries;

    /**
     * @var int
     */
    protected $numRetries;

    /**
     * Creates the CommandRetry object with the given strategy and retry count
     *
     * @param uim.cake.Core\Retry\RetryStrategyInterface $strategy The strategy to follow should the action fail
     * @param int $maxRetries The maximum number of retry attempts allowed
     */
    public this(RetryStrategyInterface $strategy, int $maxRetries = 1) {
        this.strategy = $strategy;
        this.maxRetries = $maxRetries;
    }

    /**
     * The number of retries to perform in case of failure
     *
     * @param callable $action The callable action to execute with a retry strategy
     * @return mixed The return value of the passed action callable
     * @throws \Exception
     */
    function run(callable $action) {
        this.numRetries = 0;
        while (true) {
            try {
                return $action();
            } catch (Exception $e) {
                if (
                    this.numRetries < this.maxRetries &&
                    this.strategy.shouldRetry($e, this.numRetries)
                ) {
                    this.numRetries++;
                    continue;
                }

                throw $e;
            }
        }
    }

    /**
     * Returns the last number of retry attemps.
     *
     * @return int
     */
    function getRetries(): int
    {
        return this.numRetries;
    }
}
