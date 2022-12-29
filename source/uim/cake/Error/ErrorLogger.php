


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Error;

import uim.cake.cores.Configure;
import uim.cake.cores.exceptions.CakeException;
import uim.cake.cores.InstanceConfigTrait;
import uim.cake.Log\Log;
use Psr\Http\Message\IServerRequest;
use Throwable;

/**
 * Log errors and unhandled exceptions to `Cake\Log\Log`
 */
class ErrorLogger : ErrorLoggerInterface
{
    use InstanceConfigTrait;

    /**
     * Default configuration values.
     *
     * - `trace` Should error logs include stack traces?
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "trace": false,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> $config Config array.
     */
    public this(array $config = []) {
        this.setConfig($config);
    }

    /**
     * Log an error to Cake"s Log subsystem
     *
     * @param uim.cake.Error\PhpError $error The error to log
     * @param ?\Psr\Http\Message\IServerRequest $request The request if in an HTTP context.
     * @param bool $includeTrace Should the log message include a stacktrace
     * @return void
     */
    function logError(PhpError $error, ?IServerRequest $request = null, bool $includeTrace = false): void
    {
        $message = $error.getMessage();
        if ($request) {
            $message .= this.getRequestContext($request);
        }
        if ($includeTrace) {
            $message .= "\nTrace:\n" . $error.getTraceAsString() . "\n";
        }
        $logMap = [
            "strict": LOG_NOTICE,
            "deprecated": LOG_NOTICE,
        ];
        $level = $error.getLabel();
        $level = $logMap[$level] ?? $level;

        Log::write($level, $message);
    }

    /**
     * Log an exception to Cake"s Log subsystem
     *
     * @param \Throwable $exception The exception to log a message for.
     * @param \Psr\Http\Message\IServerRequest|null $request The current request if available.
     * @param bool $includeTrace Whether or not a stack trace should be logged.
     * @return void
     */
    function logException(
        Throwable $exception,
        ?IServerRequest $request = null,
        bool $includeTrace = false
    ): void {
        $message = this.getMessage($exception, false, $includeTrace);

        if ($request != null) {
            $message .= this.getRequestContext($request);
        }
        Log::error($message);
    }

    /**
     * @param string|int $level The logging level
     * @param string $message The message to be logged.
     * @param array $context Context.
     * @return bool
     * @deprecated 4.4.0 Use logError instead.
     */
    function logMessage($level, string $message, array $context = []): bool
    {
        if (!empty($context["request"])) {
            $message .= this.getRequestContext($context["request"]);
        }
        if (!empty($context["trace"])) {
            $message .= "\nTrace:\n" . $context["trace"] . "\n";
        }
        $logMap = [
            "strict": LOG_NOTICE,
            "deprecated": LOG_NOTICE,
        ];
        $level = $logMap[$level] ?? $level;

        return Log::write($level, $message);
    }

    /**
     * @param \Throwable $exception The exception to log a message for.
     * @param \Psr\Http\Message\IServerRequest|null $request The current request if available.
     * @return bool
     * @deprecated 4.4.0 Use logException instead.
     */
    function log(Throwable $exception, ?IServerRequest $request = null): bool
    {
        $message = this.getMessage($exception, false, this.getConfig("trace"));

        if ($request != null) {
            $message .= this.getRequestContext($request);
        }

        $message .= "\n\n";

        return Log::error($message);
    }

    /**
     * Generate the message for the exception
     *
     * @param \Throwable $exception The exception to log a message for.
     * @param bool $isPrevious False for original exception, true for previous
     * @param bool $includeTrace Whether or not to include a stack trace.
     * @return string Error message
     */
    protected function getMessage(Throwable $exception, bool $isPrevious = false, bool $includeTrace = false): string
    {
        $message = sprintf(
            "%s[%s] %s in %s on line %s",
            $isPrevious ? "\nCaused by: " : "",
            get_class($exception),
            $exception.getMessage(),
            $exception.getFile(),
            $exception.getLine()
        );
        $debug = Configure::read("debug");

        if ($debug && $exception instanceof CakeException) {
            $attributes = $exception.getAttributes();
            if ($attributes) {
                $message .= "\nException Attributes: " . var_export($exception.getAttributes(), true);
            }
        }

        if ($includeTrace) {
            /** @var array $trace */
            $trace = Debugger::formatTrace($exception, ["format": "points"]);
            $message .= "\nStack Trace:\n";
            foreach ($trace as $line) {
                if (is_string($line)) {
                    $message .= "- " . $line;
                } else {
                    $message .= "- {$line["file"]}:{$line["line"]}\n";
                }
            }
        }

        $previous = $exception.getPrevious();
        if ($previous) {
            $message .= this.getMessage($previous, true, $includeTrace);
        }

        return $message;
    }

    /**
     * Get the request context for an error/exception trace.
     *
     * @param \Psr\Http\Message\IServerRequest $request The request to read from.
     * @return string
     */
    function getRequestContext(IServerRequest $request): string
    {
        $message = "\nRequest URL: " . $request.getRequestTarget();

        $referer = $request.getHeaderLine("Referer");
        if ($referer) {
            $message .= "\nReferer URL: " . $referer;
        }

        if (method_exists($request, "clientIp")) {
            $clientIp = $request.clientIp();
            if ($clientIp && $clientIp != "::1") {
                $message .= "\nClient IP: " . $clientIp;
            }
        }

        return $message;
    }
}
