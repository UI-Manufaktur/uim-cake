
module uim.cake.Error;

import uim.cake.core.Configure;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.errors.renderers.ConsoleErrorRenderer;
import uim.cake.errors.renderers.HtmlErrorRenderer;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.routings.Router;
use Exception;

/**
 * Entry point to CakePHP"s error handling.
 *
 * Using the `register()` method you can attach an ErrorTrap to PHP"s default error handler.
 *
 * When errors are trapped, errors are logged (if logging is enabled). Then the `Error.beforeRender` event is triggered.
 * Finally, errors are "rendered" using the defined renderer. If no error renderer is defined in configuration
 * one of the default implementations will be chosen based on the PHP SAPI.
 */
class ErrorTrap
{
    use EventDispatcherTrait;
    use InstanceConfigTrait;

    /**
     * Configuration options. Generally these are defined in config/app.php
     *
     * - `errorLevel` - int - The level of errors you are interested in capturing.
     * - `errorRenderer` - string - The class name of render errors with. Defaults
     *   to choosing between Html and Console based on the SAPI.
     * - `log` - boolean - Whether or not you want errors logged.
     * - `logger` - string - The class name of the error logger to use.
     * - `trace` - boolean - Whether or not backtraces should be included in
     *   logged errors.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "errorLevel": E_ALL,
        "errorRenderer": null,
        "log": true,
        "logger": ErrorLogger::class,
        "trace": false,
    ];

    /**
     * Constructor
     *
     * @param array<string, mixed> $options An options array. See _defaultConfig.
     */
    this(array $options = []) {
        this.setConfig($options);
    }

    /**
     * Choose an error renderer based on config or the SAPI
     *
     * @return class-string<uim.cake.errors.ErrorRendererInterface>
     */
    string function chooseErrorRenderer() {
        aConfig = this.getConfig("errorRenderer");
        if (aConfig != null) {
            return aConfig;
        }

        /** @var class-string<uim.cake.errors.ErrorRendererInterface> */
        return PHP_SAPI == "cli" ? ConsoleErrorRenderer::class : HtmlErrorRenderer::class;
    }

    /**
     * Attach this ErrorTrap to PHP"s default error handler.
     *
     * This will replace the existing error handler, and the
     * previous error handler will be discarded.
     *
     * This method will also set the global error level
     * via error_reporting().
     */
    void register() {
        $level = _config["errorLevel"] ?? -1;
        error_reporting($level);
        set_error_handler([this, "handleError"], $level);
    }

    /**
     * Handle an error from PHP set_error_handler
     *
     * Will use the configured renderer to generate output
     * and output it.
     *
     * This method will dispatch the `Error.beforeRender` event which can be listened
     * to on the global event manager.
     *
     * @param int $code Code of error
     * @param string $description Error description
     * @param string|null $file File on which error occurred
     * @param int|null $line Line that triggered the error
     * @return bool True if error was handled
     */
    bool handleError(
        int $code,
        string $description,
        Nullable!string $file = null,
        Nullable!int $line = null
    ) {
        if (!(error_reporting() & $code)) {
            return false;
        }
        if ($code == E_USER_ERROR || $code == E_ERROR || $code == E_PARSE) {
            throw new FatalErrorException($description, $code, $file, $line);
        }

        /** @var array $trace */
        $trace = Debugger::trace(["start": 1, "format": "points"]);
        $error = new PhpError($code, $description, $file, $line, $trace);

        $debug = Configure::read("debug");
        $renderer = this.renderer();

        try {
            // Log first incase rendering or event listeners fail
            this.logError($error);
            $event = this.dispatchEvent("Error.beforeRender", ["error": $error]);
            if ($event.isStopped()) {
                return true;
            }
            $renderer.write($renderer.render($error, $debug));
        } catch (Exception $e) {
            // Fatal errors always log.
            this.logger().logMessage("error", "Could not render error. Got: " ~ $e.getMessage());

            return false;
        }

        return true;
    }

    /**
     * Logging helper method.
     *
     * @param uim.cake.errors.PhpError $error The error object to log.
     */
    protected void logError(PhpError $error) {
        if (!_config["log"]) {
            return;
        }
        $logger = this.logger();
        if (method_exists($logger, "logError")) {
            $logger.logError($error, Router::getRequest(), _config["trace"]);
        } else {
            $loggerClass = get_class($logger);
            deprecationWarning(
                "The configured logger `{$loggerClass}` does not implement `logError()` " ~
                "which will be required in future versions of CakePHP."
            );
            $context = [];
            if (_config["trace"]) {
                $context = [
                    "trace": $error.getTraceAsString(),
                    "request": Router::getRequest(),
                ];
            }
            $logger.logMessage($error.getLabel(), $error.getMessage(), $context);
        }
    }

    /**
     * Get an instance of the renderer.
     *
     * @return uim.cake.errors.ErrorRendererInterface
     */
    function renderer(): ErrorRendererInterface
    {
        /** @var class-string<uim.cake.errors.ErrorRendererInterface> $class */
        $class = this.getConfig("errorRenderer") ?: this.chooseErrorRenderer();

        return new $class(_config);
    }

    /**
     * Get an instance of the logger.
     *
     * @return uim.cake.errors.ErrorLoggerInterface
     */
    function logger(): ErrorLoggerInterface
    {
        $oldConfig = this.getConfig("errorLogger");
        if ($oldConfig != null) {
            deprecationWarning("The `errorLogger` configuration key is deprecated. Use `logger` instead.");
            this.setConfig(["logger": $oldConfig, "errorLogger": null]);
        }

        /** @var class-string<uim.cake.errors.ErrorLoggerInterface> $class */
        $class = this.getConfig("logger", _defaultConfig["logger"]);

        return new $class(_config);
    }
}
