module uim.cake.errors;

import uim.cake.core.Configure;
import uim.cake.core.Exception\CakeException;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.Log\Log;
use Psr\Http\Message\IServerRequest;
use Throwable;

/**
 * Log errors and unhandled exceptions to `Cake\Log\Log`
 */
class ErrorLogger : IErrorLogger
{
    use InstanceConfigTrait;

    /**
     * Default configuration values.
     *
     * - `skipLog` List of exceptions to skip logging. Exceptions that
     *   extend one of the listed exceptions will also not be logged.
     * - `trace` Should error logs include stack traces?
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'skipLog' => [],
        'trace' => false,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Config array.
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }


    function logMessage($level, string myMessage, array $context = []): bool
    {
        if (!empty($context['request'])) {
            myMessage .= this.getRequestContext($context['request']);
        }
        if (!empty($context['trace'])) {
            myMessage .= "\nTrace:\n" . $context['trace'] . "\n";
        }

        return Log::write($level, myMessage);
    }


    function log(Throwable myException, ?IServerRequest myRequest = null): bool
    {
        foreach (this.getConfig('skipLog') as myClass) {
            if (myException instanceof myClass) {
                return false;
            }
        }

        myMessage = this.getMessage(myException);

        if (myRequest !== null) {
            myMessage .= this.getRequestContext(myRequest);
        }

        myMessage .= "\n\n";

        return Log::error(myMessage);
    }

    /**
     * Generate the message for the exception
     *
     * @param \Throwable myException The exception to log a message for.
     * @param bool $isPrevious False for original exception, true for previous
     * @return string Error message
     */
    protected auto getMessage(Throwable myException, bool $isPrevious = false): string
    {
        myMessage = sprintf(
            '%s[%s] %s in %s on line %s',
            $isPrevious ? "\nCaused by: " : '',
            get_class(myException),
            myException.getMessage(),
            myException.getFile(),
            myException.getLine()
        );
        $debug = Configure::read('debug');

        if ($debug && myException instanceof CakeException) {
            $attributes = myException.getAttributes();
            if ($attributes) {
                myMessage .= "\nException Attributes: " . var_export(myException.getAttributes(), true);
            }
        }

        if (this.getConfig('trace')) {
            /** @var array $trace */
            $trace = Debugger::formatTrace(myException, ['format' => 'points']);
            myMessage .= "\nStack Trace:\n";
            foreach ($trace as $line) {
                if (is_string($line)) {
                    myMessage .= '- ' . $line;
                } else {
                    myMessage .= "- {$line['file']}:{$line['line']}\n";
                }
            }
        }

        $previous = myException.getPrevious();
        if ($previous) {
            myMessage .= this.getMessage($previous, true);
        }

        return myMessage;
    }

    /**
     * Get the request context for an error/exception trace.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request to read from.
     * @return string
     */
    auto getRequestContext(IServerRequest myRequest): string
    {
        myMessage = "\nRequest URL: " . myRequest.getRequestTarget();

        $referer = myRequest.getHeaderLine('Referer');
        if ($referer) {
            myMessage .= "\nReferer URL: " . $referer;
        }

        if (method_exists(myRequest, 'clientIp')) {
            $clientIp = myRequest.clientIp();
            if ($clientIp && $clientIp !== '::1') {
                myMessage .= "\nClient IP: " . $clientIp;
            }
        }

        return myMessage;
    }
}
