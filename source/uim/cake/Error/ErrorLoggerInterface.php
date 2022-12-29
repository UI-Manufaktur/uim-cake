


 *


 * @since         4.1.0
  */
module uim.cake.Error;

use Psr\Http\Message\IServerRequest;
use Throwable;

/**
 * Interface for error logging handlers.
 *
 * Used by the ErrorHandlerMiddleware and global
 * error handlers to log exceptions and errors.
 *
 * @method void logException(\Throwable $exception, ?\Psr\Http\Message\IServerRequest $request = null, bool $includeTrace = false)
 *   Log an exception with an optional HTTP request.
 * @method void logError(\Cake\Error\PhpError $error, ?\Psr\Http\Message\IServerRequest $request = null, bool $includeTrace = false)
 *   Log an error with an optional HTTP request.
 */
interface ErrorLoggerInterface
{
    /**
     * Log an error for an exception with optional request context.
     *
     * @param \Throwable $exception The exception to log a message for.
     * @param \Psr\Http\Message\IServerRequest|null $request The current request if available.
     * @return bool
     * @deprecated 4.4.0 Implement `logException` instead.
     */
    function log(
        Throwable $exception,
        ?IServerRequest $request = null
    ): bool;

    /**
     * Log a an error message to the error logger.
     *
     * @param string|int $level The logging level
     * @param string $message The message to be logged.
     * @param array $context Context.
     * @return bool
     * @deprecated 4.4.0 Implement `logError` instead.
     */
    function logMessage($level, string $message, array $context = []): bool;
}
