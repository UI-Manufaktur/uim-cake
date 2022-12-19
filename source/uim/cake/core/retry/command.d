module uim.cake.core.retry.commandretry;

@safe:
import uim.cake;

/**
 * Allows any action to be retried in case of an exception.
 *
 * This class can be parametrized with a strategy, which will be followed
 * to determine whether the action should be retried.
 */
class CommandRetry {
    /**
     * The strategy to follow should the executed action fail.
     *
     * @var \Cake\Core\Retry\IRetryStrategy
     */
    protected strategy;

    protected int maxRetries;

    protected int numRetries;

    /**
     * Creates the CommandRetry object with the given strategy and retry count
     *
     * @param \Cake\Core\Retry\IRetryStrategy $strategy The strategy to follow should the action fail
     * @param int $maxRetries The maximum number of retry attempts allowed
     */
    this(IRetryStrategy $strategy, int $maxRetries = 1) {
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
     */
    int getRetries() {
        return this.numRetries;
    }
}
