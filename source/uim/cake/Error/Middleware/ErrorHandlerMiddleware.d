

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.errorss\Middleware;

import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.errorss\ErrorHandler;
import uim.cake.errorss\ExceptionRenderer;
import uim.cake.Http\Exception\RedirectException;
import uim.cake.Http\Response;
use InvalidArgumentException;
use Laminas\Diactoros\Response\RedirectResponse;
use Psr\Http\Message\IResponse;
use Psr\Http\Message\IServerRequest;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface;
use Throwable;

/**
 * Error handling middleware.
 *
 * Traps exceptions and converts them into HTML or content-type appropriate
 * error pages using the CakePHP ExceptionRenderer.
 */
class ErrorHandlerMiddleware : MiddlewareInterface
{
    use InstanceConfigTrait;

    /**
     * Default configuration values.
     *
     * Ignored if contructor is passed an ErrorHandler instance.
     *
     * - `log` Enable logging of exceptions.
     * - `skipLog` List of exceptions to skip logging. Exceptions that
     *   extend one of the listed exceptions will also not be logged. Example:
     *
     *   ```
     *   'skipLog' => ['Cake\Error\NotFoundException', 'Cake\Error\UnauthorizedException']
     *   ```
     *
     * - `trace` Should error logs include stack traces?
     * - `exceptionRenderer` The renderer instance or class name to use or a callable factory
     *   which returns a \Cake\Error\ExceptionRendererInterface instance.
     *   Defaults to \Cake\Error\ExceptionRenderer
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'skipLog' => [],
        'log' => true,
        'trace' => false,
        'exceptionRenderer' => ExceptionRenderer::class,
    ];

    /**
     * Error handler instance.
     *
     * @var \Cake\Error\ErrorHandler|null
     */
    protected myErrorHandler;

    /**
     * Constructor
     *
     * @param \Cake\Error\ErrorHandler|array myErrorHandler The error handler instance
     *  or config array.
     * @throws \InvalidArgumentException
     */
    this(myErrorHandler = []) {
        if (func_num_args() > 1) {
            deprecationWarning(
                'The signature of ErrorHandlerMiddleware::this() has changed. '
                . 'Pass the config array as 1st argument instead.'
            );

            myErrorHandler = func_get_arg(1);
        }

        if (PHP_VERSION_ID >= 70400 && Configure::read('debug')) {
            ini_set('zend.exception_ignore_args', '0');
        }

        if (is_array(myErrorHandler)) {
            this.setConfig(myErrorHandler);

            return;
        }

        if (!myErrorHandler instanceof ErrorHandler) {
            throw new InvalidArgumentException(sprintf(
                'myErrorHandler argument must be a config array or ErrorHandler instance. Got `%s` instead.',
                getTypeName(myErrorHandler)
            ));
        }

        this.errorHandler = myErrorHandler;
    }

    /**
     * Wrap the remaining middleware with error handling.
     *
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @param \Psr\Http\Server\RequestHandlerInterface $handler The request handler.
     * @return \Psr\Http\Message\IResponse A response.
     */
    function process(IServerRequest myRequest, RequestHandlerInterface $handler): IResponse
    {
        try {
            return $handler.handle(myRequest);
        } catch (RedirectException myException) {
            return this.handleRedirect(myException);
        } catch (Throwable myException) {
            return this.handleException(myException, myRequest);
        }
    }

    /**
     * Handle an exception and generate an error response
     *
     * @param \Throwable myException The exception to handle.
     * @param \Psr\Http\Message\IServerRequest myRequest The request.
     * @return \Psr\Http\Message\IResponse A response
     */
    function handleException(Throwable myException, IServerRequest myRequest): IResponse
    {
        myErrorHandler = this.getErrorHandler();
        $renderer = myErrorHandler.getRenderer(myException, myRequest);

        try {
            myErrorHandler.logException(myException, myRequest);
            $response = $renderer.render();
        } catch (Throwable $internalException) {
            myErrorHandler.logException($internalException, myRequest);
            $response = this.handleInternalError();
        }

        return $response;
    }

    /**
     * Convert a redirect exception into a response.
     *
     * @param \Cake\Http\Exception\RedirectException myException The exception to handle
     * @return \Psr\Http\Message\IResponse Response created from the redirect.
     */
    function handleRedirect(RedirectException myException): IResponse
    {
        return new RedirectResponse(
            myException.getMessage(),
            myException.getCode(),
            myException.getHeaders()
        );
    }

    /**
     * Handle internal errors.
     *
     * @return \Psr\Http\Message\IResponse A response
     */
    protected auto handleInternalError(): IResponse
    {
        $response = new Response(['body' => 'An Internal Server Error Occurred']);

        return $response.withStatus(500);
    }

    /**
     * Get a error handler instance
     *
     * @return \Cake\Error\ErrorHandler The error handler.
     */
    protected auto getErrorHandler(): ErrorHandler
    {
        if (this.errorHandler === null) {
            /** @var class-string<\Cake\Error\ErrorHandler> myClassName */
            myClassName = App::className('ErrorHandler', 'Error');
            this.errorHandler = new myClassName(this.getConfig());
        }

        return this.errorHandler;
    }
}
