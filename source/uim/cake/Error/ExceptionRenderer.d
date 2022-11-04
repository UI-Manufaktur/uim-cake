module uim.cake.errors;

import uim.cake.controller\Controller;
import uim.cake.controller\ControllerFactory;
import uim.cake.controller\Exception\InvalidParameterException;
import uim.cake.controller\Exception\MissingActionException;
import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Container;
import uim.cake.core.Exception\CakeException;
import uim.cake.core.Exception\MissingPluginException;
import uim.cake.Datasource\Exception\PageOutOfBoundsException;
import uim.cake.Datasource\Exception\RecordNotFoundException;
import uim.cake.events\Event;
import uim.cake.Http\Exception\HttpException;
import uim.cake.Http\Exception\MissingControllerException;
import uim.cake.Http\Response;
import uim.cake.Http\ServerRequest;
import uim.cake.Http\ServerRequestFactory;
import uim.cake.Routing\Exception\MissingRouteException;
import uim.cake.Routing\Router;
import uim.cake.utikities.Inflector;
import uim.cake.views\Exception\MissingLayoutException;
import uim.cake.views\Exception\MissingTemplateException;
use PDOException;
use Psr\Http\Message\IResponse;
use Throwable;

/**
 * Exception Renderer.
 *
 * Captures and handles all unhandled exceptions. Displays helpful framework errors when debug is true.
 * When debug is false a ExceptionRenderer will render 404 or 500 errors. If an uncaught exception is thrown
 * and it is a type that ExceptionHandler does not know about it will be treated as a 500 error.
 *
 * ### Implementing application specific exception rendering
 *
 * You can implement application specific exception handling by creating a subclass of
 * ExceptionRenderer and configure it to be the `exceptionRenderer` in config/error.php
 *
 * #### Using a subclass of ExceptionRenderer
 *
 * Using a subclass of ExceptionRenderer gives you full control over how Exceptions are rendered, you
 * can configure your class in your config/app.php.
 */
class ExceptionRenderer : ExceptionRendererInterface
{
    /**
     * The exception being handled.
     *
     * @var \Throwable
     */
    protected myError;

    /**
     * Controller instance.
     *
     * @var \Cake\Controller\Controller
     */
    protected $controller;

    /**
     * Template to render for {@link \Cake\Core\Exception\CakeException}
     *
     * @var string
     */
    protected myTemplate = '';

    /**
     * The method corresponding to the Exception this object is for.
     *
     * @var string
     */
    protected $method = '';

    /**
     * If set, this will be request used to create the controller that will render
     * the error.
     *
     * @var \Cake\Http\ServerRequest|null
     */
    protected myRequest;

    /**
     * Map of exceptions to http status codes.
     *
     * This can be customized for users that don't want specific exceptions to throw 404 errors
     * or want their application exceptions to be automatically converted.
     *
     * @var array<string, int>
     * @psalm-var array<class-string<\Throwable>, int>
     */
    protected myExceptionHttpCodes = [
        // Controller exceptions
        InvalidParameterException::class => 404,
        MissingActionException::class => 404,
        // Datasource exceptions
        PageOutOfBoundsException::class => 404,
        RecordNotFoundException::class => 404,
        // Http exceptions
        MissingControllerException::class => 404,
        // Routing exceptions
        MissingRouteException::class => 404,
    ];

    /**
     * Creates the controller to perform rendering on the error response.
     *
     * @param \Throwable myException Exception.
     * @param \Cake\Http\ServerRequest|null myRequest The request if this is set it will be used
     *   instead of creating a new one.
     */
    this(Throwable myException, ?ServerRequest myRequest = null) {
        this.error = myException;
        this.request = myRequest;
        this.controller = this._getController();
    }

    /**
     * Get the controller instance to handle the exception.
     * Override this method in subclasses to customize the controller used.
     * This method returns the built in `ErrorController` normally, or if an error is repeated
     * a bare controller will be used.
     *
     * @return \Cake\Controller\Controller
     * @triggers Controller.startup $controller
     */
    protected auto _getController(): Controller
    {
        myRequest = this.request;
        $routerRequest = Router::getRequest();
        // Fallback to the request in the router or make a new one from
        // $_SERVER
        if (myRequest === null) {
            myRequest = $routerRequest ?: ServerRequestFactory::fromGlobals();
        }

        // If the current request doesn't have routing data, but we
        // found a request in the router context copy the params over
        if (myRequest.getParam('controller') === null && $routerRequest !== null) {
            myRequest = myRequest.withAttribute('params', $routerRequest.getAttribute('params'));
        }

        myErrorOccured = false;
        try {
            myParams = myRequest.getAttribute('params');
            myParams['controller'] = 'Error';

            $factory = new ControllerFactory(new Container());
            myClass = $factory.getControllerClass(myRequest.withAttribute('params', myParams));

            if (!myClass) {
                /** @var string myClass */
                myClass = App::className('Error', 'Controller', 'Controller');
            }

            /** @var \Cake\Controller\Controller $controller */
            $controller = new myClass(myRequest);
            $controller.startupProcess();
        } catch (Throwable $e) {
            myErrorOccured = true;
        }

        if (!isset($controller)) {
            return new Controller(myRequest);
        }

        // Retry RequestHandler, as another aspect of startupProcess()
        // could have failed. Ignore any exceptions out of startup, as
        // there could be userland input data parsers.
        if (myErrorOccured && isset($controller.RequestHandler)) {
            try {
                myEvent = new Event('Controller.startup', $controller);
                $controller.RequestHandler.startup(myEvent);
            } catch (Throwable $e) {
            }
        }

        return $controller;
    }

    /**
     * Clear output buffers so error pages display properly.
     *
     * @return void
     */
    protected auto clearOutput(): void
    {
        if (in_array(PHP_SAPI, ['cli', 'phpdbg'])) {
            return;
        }
        while (ob_get_level()) {
            ob_end_clean();
        }
    }

    /**
     * Renders the response for the exception.
     *
     * @return \Cake\Http\Response The response to be sent.
     */
    function render(): IResponse
    {
        myException = this.error;
        $code = this.getHttpCode(myException);
        $method = this._method(myException);
        myTemplate = this._template(myException, $method, $code);
        this.clearOutput();

        if (method_exists(this, $method)) {
            return this._customMethod($method, myException);
        }

        myMessage = this._message(myException, $code);
        myUrl = this.controller.getRequest().getRequestTarget();
        $response = this.controller.getResponse();

        if (myException instanceof CakeException) {
            /** @psalm-suppress DeprecatedMethod */
            foreach ((array)myException.responseHeader() as myKey => myValue) {
                $response = $response.withHeader(myKey, myValue);
            }
        }
        if (myException instanceof HttpException) {
            foreach (myException.getHeaders() as myName => myValue) {
                $response = $response.withHeader(myName, myValue);
            }
        }
        $response = $response.withStatus($code);

        $viewVars = [
            'message' => myMessage,
            'url' => h(myUrl),
            'error' => myException,
            'code' => $code,
        ];
        $serialize = ['message', 'url', 'code'];

        $isDebug = Configure::read('debug');
        if ($isDebug) {
            $trace = (array)Debugger::formatTrace(myException.getTrace(), [
                'format' => 'array',
                'args' => false,
            ]);
            $origin = [
                'file' => myException.getFile() ?: 'null',
                'line' => myException.getLine() ?: 'null',
            ];
            // Traces don't include the origin file/line.
            array_unshift($trace, $origin);
            $viewVars['trace'] = $trace;
            $viewVars += $origin;
            $serialize[] = 'file';
            $serialize[] = 'line';
        }
        this.controller.set($viewVars);
        this.controller.viewBuilder().setOption('serialize', $serialize);

        if (myException instanceof CakeException && $isDebug) {
            this.controller.set(myException.getAttributes());
        }
        this.controller.setResponse($response);

        return this._outputMessage(myTemplate);
    }

    /**
     * Render a custom error method/template.
     *
     * @param string $method The method name to invoke.
     * @param \Throwable myException The exception to render.
     * @return \Cake\Http\Response The response to send.
     */
    protected auto _customMethod(string $method, Throwable myException): Response
    {
        myResult = this.{$method}(myException);
        this._shutdown();
        if (is_string(myResult)) {
            myResult = this.controller.getResponse().withStringBody(myResult);
        }

        return myResult;
    }

    /**
     * Get method name
     *
     * @param \Throwable myException Exception instance.
     * @return string
     */
    protected string _method(Throwable myException) {
        [, $baseClass] = moduleSplit(get_class(myException));

        if (substr($baseClass, -9) === 'Exception') {
            $baseClass = substr($baseClass, 0, -9);
        }

        // $baseClass would be an empty string if the exception class is \Exception.
        $method = $baseClass === '' ? 'error500' : Inflector::variable($baseClass);

        return this.method = $method;
    }

    /**
     * Get error message.
     *
     * @param \Throwable myException Exception.
     * @param int $code Error code.
     * @return string Error message
     */
    protected string _message(Throwable myException, int $code) {
        myMessage = myException.getMessage();

        if (
            !Configure::read('debug') &&
            !(myException instanceof HttpException)
        ) {
            if ($code < 500) {
                myMessage = __d('cake', 'Not Found');
            } else {
                myMessage = __d('cake', 'An Internal Error Has Occurred.');
            }
        }

        return myMessage;
    }

    /**
     * Get template for rendering exception info.
     *
     * @param \Throwable myException Exception instance.
     * @param string $method Method name.
     * @param int $code Error code.
     * @return string Template name
     */
    protected string _template(Throwable myException, string $method, int $code) {
        if (myException instanceof HttpException || !Configure::read('debug')) {
            return this.template = $code < 500 ? 'error400' : 'error500';
        }

        if (myException instanceof PDOException) {
            return this.template = 'pdo_error';
        }

        return this.template = $method;
    }

    /**
     * Gets the appropriate http status code for exception.
     *
     * @param \Throwable myException Exception.
     * @return int A valid HTTP status code.
     */
    protected auto getHttpCode(Throwable myException): int
    {
        if (myException instanceof HttpException) {
            return myException.getCode();
        }

        return this.exceptionHttpCodes[get_class(myException)] ?? 500;
    }

    /**
     * Generate the response using the controller object.
     *
     * @param string myTemplate The template to render.
     * @return \Cake\Http\Response A response object that can be sent.
     */
    protected auto _outputMessage(string myTemplate): Response
    {
        try {
            this.controller.render(myTemplate);

            return this._shutdown();
        } catch (MissingTemplateException $e) {
            $attributes = $e.getAttributes();
            if (
                $e instanceof MissingLayoutException ||
                strpos($attributes['file'], 'error500') !== false
            ) {
                return this._outputMessageSafe('error500');
            }

            return this._outputMessage('error500');
        } catch (MissingPluginException $e) {
            $attributes = $e.getAttributes();
            if (isset($attributes['plugin']) && $attributes['plugin'] === this.controller.getPlugin()) {
                this.controller.setPlugin(null);
            }

            return this._outputMessageSafe('error500');
        } catch (Throwable $e) {
            return this._outputMessageSafe('error500');
        }
    }

    /**
     * A safer way to render error messages, replaces all helpers, with basics
     * and doesn't call component methods.
     *
     * @param string myTemplate The template to render.
     * @return \Cake\Http\Response A response object that can be sent.
     */
    protected auto _outputMessageSafe(string myTemplate): Response
    {
        myBuilder = this.controller.viewBuilder();
        myBuilder
            .setHelpers([], false)
            .setLayoutPath('')
            .setTemplatePath('Error');
        $view = this.controller.createView('View');

        $response = this.controller.getResponse()
            .withType('html')
            .withStringBody($view.render(myTemplate, 'error'));
        this.controller.setResponse($response);

        return $response;
    }

    /**
     * Run the shutdown events.
     *
     * Triggers the afterFilter and afterDispatch events.
     *
     * @return \Cake\Http\Response The response to serve.
     */
    protected auto _shutdown(): Response
    {
        this.controller.dispatchEvent('Controller.shutdown');

        return this.controller.getResponse();
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    auto __debugInfo(): array
    {
        return [
            'error' => this.error,
            'request' => this.request,
            'controller' => this.controller,
            'template' => this.template,
            'method' => this.method,
        ];
    }
}
