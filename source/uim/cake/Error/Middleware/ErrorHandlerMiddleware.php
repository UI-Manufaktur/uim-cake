


 *


 * @since         3.3.0
  */module uim.cake.errors.Middleware;

import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.errors.ErrorHandler;
import uim.cake.errors.ExceptionTrap;
import uim.cake.errors.renderers.WebExceptionRenderer;
import uim.cake.http.exceptions.RedirectException;
import uim.cake.http.Response;
use InvalidArgumentException;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\messages.IResponse;
use Psr\Http\messages.IServerRequest;
use Psr\Http\servers.IMiddleware;
use Psr\Http\servers.RequestHandlerInterface;
use Throwable;

/**
 * Error handling middleware.
 *
 * Traps exceptions and converts them into HTML or content-type appropriate
 * error pages using the CakePHP ExceptionRenderer.
 */
class ErrorHandlerMiddleware : IMiddleware
{
    use InstanceConfigTrait;

    /**
     * Default configuration values.
     *
     * Ignored if contructor is passed an ExceptionTrap instance.
     *
     * Configuration keys and values are shared with `ExceptionTrap`.
     * This class will pass its configuration onto the ExceptionTrap
     * class if you are using the array style constructor.
     *
     * @var array<string, mixed>
     * @see uim.cake.errors.ExceptionTrap
     */
    protected $_defaultConfig = [
        "exceptionRenderer": WebExceptionRenderer::class,
    ];

    /**
     * Error handler instance.
     *
     * @var uim.cake.errors.ErrorHandler|null
     */
    protected $errorHandler = null;

    /**
     * ExceptionTrap instance
     *
     * @var uim.cake.errors.ExceptionTrap|null
     */
    protected $exceptionTrap = null;

    /**
     * Constructor
     *
     * @param uim.cake.errors.ErrorHandler|uim.cake.errors.ExceptionTrap|array $errorHandler The error handler instance
     *  or config array.
     * @throws \InvalidArgumentException
     */
    this($errorHandler = []) {
        if (func_num_args() > 1) {
            deprecationWarning(
                "The signature of ErrorHandlerMiddleware::__construct() has changed~ "
                ~ "Pass the config array as 1st argument instead."
            );

            $errorHandler = func_get_arg(1);
        }

        if (PHP_VERSION_ID >= 70400 && Configure::read("debug")) {
            ini_set("zend.exception_ignore_args", "0");
        }

        if (is_array($errorHandler)) {
            this.setConfig($errorHandler);

            return;
        }
        if ($errorHandler instanceof ErrorHandler) {
            deprecationWarning(
                "Using an `ErrorHandler` is deprecated. You should migate to the `ExceptionTrap` sub-system instead."
            );
            this.errorHandler = $errorHandler;

            return;
        }
        if ($errorHandler instanceof ExceptionTrap) {
            this.exceptionTrap = $errorHandler;

            return;
        }
        throw new InvalidArgumentException(sprintf(
            "$errorHandler argument must be a config array or ExceptionTrap instance. Got `%s` instead.",
            getTypeName($errorHandler)
        ));
    }

    /**
     * Wrap the remaining middleware with error handling.
     *
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @param \Psr\Http\servers.RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\messages.IResponse A response
     */
    function process(IServerRequest $request, RequestHandlerInterface $handler): IResponse
    {
        try {
            return $handler.handle($request);
        } catch (RedirectException $exception) {
            return this.handleRedirect($exception);
        } catch (Throwable $exception) {
            return this.handleException($exception, $request);
        }
    }

    /**
     * Handle an exception and generate an error response
     *
     * @param \Throwable $exception The exception to handle.
     * @param \Psr\Http\messages.IServerRequest $request The request.
     * @return \Psr\Http\messages.IResponse A response.
     */
    function handleException(Throwable $exception, IServerRequest $request): IResponse
    {
        if (this.errorHandler == null) {
            $handler = this.getExceptionTrap();
            $handler.logException($exception, $request);

            $renderer = $handler.renderer($exception, $request);
        } else {
            $handler = this.getErrorHandler();
            $handler.logException($exception, $request);

            $renderer = $handler.getRenderer($exception, $request);
        }

        try {
            /** @var \Psr\Http\messages.IResponse|string $response */
            $response = $renderer.render();
            if (is_string($response)) {
                return new Response(["body": $response, "status": 500]);
            }

            return $response;
        } catch (Throwable $internalException) {
            $handler.logException($internalException, $request);

            return this.handleInternalError();
        }
    }

    /**
     * Convert a redirect exception into a response.
     *
     * @param uim.cake.http.exceptions.RedirectException $exception The exception to handle
     * @return \Psr\Http\messages.IResponse Response created from the redirect.
     */
    function handleRedirect(RedirectException $exception): IResponse
    {
        return new RedirectResponse(
            $exception.getMessage(),
            $exception.getCode(),
            $exception.getHeaders()
        );
    }

    /**
     * Handle internal errors.
     *
     * @return \Psr\Http\messages.IResponse A response
     */
    protected function handleInternalError(): IResponse
    {
        return new Response([
            "body": "An Internal Server Error Occurred",
            "status": 500,
        ]);
    }

    /**
     * Get a error handler instance
     *
     * @return uim.cake.errors.ErrorHandler The error handler.
     */
    protected function getErrorHandler(): ErrorHandler
    {
        if (this.errorHandler == null) {
            /** @var class-string<uim.cake.errors.ErrorHandler> $className */
            $className = App::className("ErrorHandler", "Error");
            this.errorHandler = new $className(this.getConfig());
        }

        return this.errorHandler;
    }

    /**
     * Get a exception trap instance
     *
     * @return uim.cake.errors.ExceptionTrap The exception trap.
     */
    protected function getExceptionTrap(): ExceptionTrap
    {
        if (this.exceptionTrap == null) {
            /** @var class-string<uim.cake.errors.ExceptionTrap> $className */
            $className = App::className("ExceptionTrap", "Error");
            this.exceptionTrap = new $className(this.getConfig());
        }

        return this.exceptionTrap;
    }
}
