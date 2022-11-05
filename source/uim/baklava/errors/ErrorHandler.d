module uim.baklava.errors;

import uim.baklava.core.App;
import uim.baklava.https\ResponseEmitter;
import uim.baklava.routings\Router;
use Psr\Http\Message\IServerRequest;
use RuntimeException;
use Throwable;

/**
 * Error Handler provides basic error and exception handling for your application. It captures and
 * handles all unhandled exceptions and errors. Displays helpful framework errors when debug mode is on.
 *
 * ### Uncaught exceptions
 *
 * When debug mode is off a ExceptionRenderer will render 404 or 500 errors. If an uncaught exception is thrown
 * and it is a type that ExceptionRenderer does not know about it will be treated as a 500 error.
 *
 * ### Implementing application specific exception handling
 *
 * You can implement application specific exception handling in one of a few ways. Each approach
 * gives you different amounts of control over the exception handling process.
 *
 * - Modify config/error.php and setup custom exception handling.
 * - Use the `exceptionRenderer` option to inject an Exception renderer. This will
 *   let you keep the existing handling logic but override the rendering logic.
 *
 * #### Create your own Exception handler
 *
 * This gives you full control over the exception handling process. The class you choose should be
 * loaded in your config/error.php and registered as the default exception handler.
 *
 * #### Using a custom renderer with `exceptionRenderer`
 *
 * If you don't want to take control of the exception handling, but want to change how exceptions are
 * rendered you can use `exceptionRenderer` option to choose a class to render exception pages. By default
 * `Cake\Error\ExceptionRenderer` is used. Your custom exception renderer class should be placed in src/Error.
 *
 * Your custom renderer should expect an exception in its constructor, and implement a render method.
 * Failing to do so will cause additional errors.
 *
 * #### Logging exceptions
 *
 * Using the built-in exception handling, you can log all the exceptions
 * that are dealt with by ErrorHandler by setting `log` option to true in your config/error.php.
 * Enabling this will log every exception to Log and the configured loggers.
 *
 * ### PHP errors
 *
 * Error handler also provides the built in features for handling php errors (trigger_error).
 * While in debug mode, errors will be output to the screen using debugger. While in production mode,
 * errors will be logged to Log. You can control which errors are logged by setting
 * `errorLevel` option in config/error.php.
 *
 * #### Logging errors
 *
 * When ErrorHandler is used for handling errors, you can enable error logging by setting the `log`
 * option to true. This will log all errors to the configured log handlers.
 *
 * #### Controlling what errors are logged/displayed
 *
 * You can control which errors are logged / displayed by ErrorHandler by setting `errorLevel`. Setting this
 * to one or a combination of a few of the E_* constants will only enable the specified errors:
 *
 * ```
 * myOptions['errorLevel'] = E_ALL & ~E_NOTICE;
 * ```
 *
 * Would enable handling for all non Notice errors.
 *
 * @see \Cake\Error\ExceptionRenderer for more information on how to customize exception rendering.
 */
class ErrorHandler : BaseErrorHandler
{
    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig The options for error handling.
     */
    this(array myConfig = []) {
        myConfig += [
            'exceptionRenderer' => ExceptionRenderer::class,
        ];

        this.setConfig(myConfig);
    }

    /**
     * Display an error.
     *
     * Template method of BaseErrorHandler.
     *
     * @param array myError An array of error data.
     * @param bool $debug Whether the app is in debug mode.
     * @return void
     */
    protected auto _displayError(array myError, bool $debug): void
    {
        if (!$debug) {
            return;
        }
        Debugger::getInstance().outputError(myError);
    }

    /**
     * Displays an exception response body.
     *
     * @param \Throwable myException The exception to display.
     * @return void
     * @throws \Exception When the chosen exception renderer is invalid.
     */
    protected auto _displayException(Throwable myException): void
    {
        try {
            $renderer = this.getRenderer(
                myException,
                Router::getRequest()
            );
            $response = $renderer.render();
            this._sendResponse($response);
        } catch (Throwable myException) {
            this._logInternalError(myException);
        }
    }

    /**
     * Get a renderer instance.
     *
     * @param \Throwable myException The exception being rendered.
     * @param \Psr\Http\Message\IServerRequest|null myRequest The request.
     * @return \Cake\Error\ExceptionRendererInterface The exception renderer.
     * @throws \RuntimeException When the renderer class cannot be found.
     */
    auto getRenderer(
        Throwable myException,
        ?IServerRequest myRequest = null
    ): ExceptionRendererInterface {
        $renderer = this._config['exceptionRenderer'];

        if (is_string($renderer)) {
            /** @var class-string<\Cake\Error\ExceptionRendererInterface>|null myClass */
            myClass = App::className($renderer, 'Error');
            if (!myClass) {
                throw new RuntimeException(sprintf(
                    "The '%s' renderer class could not be found.",
                    $renderer
                ));
            }

            return new myClass(myException, myRequest);
        }

        /** @var callable $factory */
        $factory = $renderer;

        return $factory(myException, myRequest);
    }

    /**
     * Log internal errors.
     *
     * @param \Throwable myException Exception.
     * @return void
     */
    protected auto _logInternalError(Throwable myException): void
    {
        // Disable trace for internal errors.
        this._config['trace'] = false;
        myMessage = sprintf(
            "[%s] %s (%s:%s)\n%s", // Keeping same message format
            get_class(myException),
            myException.getMessage(),
            myException.getFile(),
            myException.getLine(),
            myException.getTraceAsString()
        );
        trigger_error(myMessage, E_USER_ERROR);
    }

    /**
     * Method that can be easily stubbed in testing.
     *
     * @param \Cake\Http\Response|string $response Either the message or response object.
     * @return void
     */
    protected auto _sendResponse($response): void
    {
        if (is_string($response)) {
            echo $response;

            return;
        }

        $emitter = new ResponseEmitter();
        $emitter.emit($response);
    }
}
