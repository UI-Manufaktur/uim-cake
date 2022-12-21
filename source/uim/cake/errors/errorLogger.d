module uim.cake.errors;

import uim.cake.core.Configure;
import uim.cake.core.exceptions\CakeException;
import uim.cake.core.InstanceConfigTrait;
import uim.cakegs\Log;
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
    protected STRINGAA _defaultConfig = [
        "skipLog":[],
        "trace":false,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Config array.
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }


    bool logMessage($level, string myMessage, array $context = []) {
        if (!empty($context["request"])) {
            myMessage .= this.getRequestContext($context["request"]);
        }
        if (!empty($context["trace"])) {
            myMessage .= "\nTrace:\n" . $context["trace"] . "\n";
        }

        return Log::write($level, myMessage);
    }


    bool log(Throwable myException, ?IServerRequest myRequest = null) {
        foreach (this.getConfig("skipLog") as myClass) {
            if (myException instanceof myClass) {
                return false;
            }
        }

        myMessage = this.getMessage(myException);

        if (myRequest  !is null) {
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
    protected string getMessage(Throwable myException, bool $isPrevious = false) {
        myMessage = sprintf(
            "%s[%s] %s in %s on line %s",
            $isPrevious ? "\nCaused by: " : "",
            get_class(myException),
            myException.getMessage(),
            myException.getFile(),
            myException.getLine()
        );
        $debug = Configure::read("debug");

        if ($debug && myException instanceof CakeException) {
            $attributes = myException.getAttributes();
            if ($attributes) {
                myMessage .= "\nException Attributes: " . var_export(myException.getAttributes(), true);
            }
        }

        if (this.getConfig("trace")) {
            /** @var array $trace */
            $trace = Debugger::formatTrace(myException, ["format":"points"]);
            myMessage .= "\nStack Trace:\n";
            foreach ($trace as $line) {
                if (is_string($line)) {
                    myMessage .= "- " . $line;
                } else {
                    myMessage .= "- {$line["file"]}:{$line["line"]}\n";
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
     */
    string getRequestContext(IServerRequest myRequest) {
        myMessage = "\nRequest URL: " . myRequest.getRequestTarget();

        $referer = myRequest.getHeaderLine("Referer");
        if ($referer) {
            myMessage .= "\nReferer URL: " . $referer;
        }

        if (method_exists(myRequest, "clientIp")) {
            $clientIp = myRequest.clientIp();
            if ($clientIp && $clientIp !== "::1") {
                myMessage .= "\nClient IP: " . $clientIp;
            }
        }

        return myMessage;
    }
}
