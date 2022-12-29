

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite;

import uim.cake.controllers.Controller;
import uim.cake.cores.Configure;
import uim.cake.cores.TestSuite\ContainerStubTrait;
import uim.cake.databases.exceptions.DatabaseException;
import uim.cake.errors.Renderer\WebExceptionRenderer;
import uim.cake.events.EventInterface;
import uim.cake.events.EventManager;
import uim.cake.Form\FormProtector;
import uim.cake.http.Middleware\CsrfProtectionMiddleware;
import uim.cake.http.Session;
import uim.cake.Routing\Router;
import uim.cake.TestSuite\Constraint\Response\BodyContains;
import uim.cake.TestSuite\Constraint\Response\BodyEmpty;
import uim.cake.TestSuite\Constraint\Response\BodyEquals;
import uim.cake.TestSuite\Constraint\Response\BodyNotContains;
import uim.cake.TestSuite\Constraint\Response\BodyNotEmpty;
import uim.cake.TestSuite\Constraint\Response\BodyNotEquals;
import uim.cake.TestSuite\Constraint\Response\BodyNotRegExp;
import uim.cake.TestSuite\Constraint\Response\BodyRegExp;
import uim.cake.TestSuite\Constraint\Response\ContentType;
import uim.cake.TestSuite\Constraint\Response\CookieEncryptedEquals;
import uim.cake.TestSuite\Constraint\Response\CookieEquals;
import uim.cake.TestSuite\Constraint\Response\CookieNotSet;
import uim.cake.TestSuite\Constraint\Response\CookieSet;
import uim.cake.TestSuite\Constraint\Response\FileSent;
import uim.cake.TestSuite\Constraint\Response\FileSentAs;
import uim.cake.TestSuite\Constraint\Response\HeaderContains;
import uim.cake.TestSuite\Constraint\Response\HeaderEquals;
import uim.cake.TestSuite\Constraint\Response\HeaderNotContains;
import uim.cake.TestSuite\Constraint\Response\HeaderNotSet;
import uim.cake.TestSuite\Constraint\Response\HeaderSet;
import uim.cake.TestSuite\Constraint\Response\StatusCode;
import uim.cake.TestSuite\Constraint\Response\StatusError;
import uim.cake.TestSuite\Constraint\Response\StatusFailure;
import uim.cake.TestSuite\Constraint\Response\StatusOk;
import uim.cake.TestSuite\Constraint\Response\StatusSuccess;
import uim.cake.TestSuite\Constraint\Session\FlashParamEquals;
import uim.cake.TestSuite\Constraint\Session\SessionEquals;
import uim.cake.TestSuite\Constraint\Session\SessionHasKey;
import uim.cake.TestSuite\Constraint\View\LayoutFileEquals;
import uim.cake.TestSuite\Constraint\View\TemplateFileEquals;
import uim.cake.TestSuite\Stub\TestExceptionRenderer;
import uim.cake.utilities.CookieCryptTrait;
import uim.cake.utilities.Hash;
import uim.cake.utilities.Security;
use Exception;
use Laminas\Diactoros\Uri;
use PHPUnit\Exception as PHPUnitException;
use Throwable;

/**
 * A trait intended to make integration tests of your controllers easier.
 *
 * This test class provides a number of helper methods and features
 * that make dispatching requests and checking their responses simpler.
 * It favours full integration tests over mock objects as you can test
 * more of your code easily and avoid some of the maintenance pitfalls
 * that mock objects create.
 */
trait IntegrationTestTrait
{
    use CookieCryptTrait;
    use ContainerStubTrait;

    /**
     * The data used to build the next request.
     *
     * @var array
     */
    protected $_request = [];

    /**
     * The response for the most recent request.
     *
     * @var \Psr\Http\Message\IResponse|null
     */
    protected $_response;

    /**
     * The exception being thrown if the case.
     *
     * @var \Throwable|null
     */
    protected $_exception;

    /**
     * Session data to use in the next request.
     *
     * @var array
     */
    protected $_session = [];

    /**
     * Cookie data to use in the next request.
     *
     * @var array
     */
    protected $_cookie = [];

    /**
     * The controller used in the last request.
     *
     * @var uim.cake.controllers.Controller|null
     */
    protected $_controller;

    /**
     * The last rendered view
     *
     * @var string
     */
    protected $_viewName;

    /**
     * The last rendered layout
     *
     * @var string
     */
    protected $_layoutName;

    /**
     * The session instance from the last request
     *
     * @var uim.cake.http.Session
     */
    protected $_requestSession;

    /**
     * Boolean flag for whether the request should have
     * a SecurityComponent token added.
     *
     * @var bool
     */
    protected $_securityToken = false;

    /**
     * Boolean flag for whether the request should have
     * a CSRF token added.
     *
     * @var bool
     */
    protected $_csrfToken = false;

    /**
     * Boolean flag for whether the request should re-store
     * flash messages
     *
     * @var bool
     */
    protected $_retainFlashMessages = false;

    /**
     * Stored flash messages before render
     *
     * @var array
     */
    protected $_flashMessages = [];

    /**
     * @var string|null
     */
    protected $_cookieEncryptionKey;

    /**
     * List of fields that are excluded from field validation.
     *
     * @var array<string>
     */
    protected $_unlockedFields = [];

    /**
     * The name that will be used when retrieving the csrf token.
     *
     * @var string
     */
    protected $_csrfKeyName = "csrfToken";

    /**
     * Clears the state used for requests.
     *
     * @after
     * @return void
     * @psalm-suppress PossiblyNullPropertyAssignmentValue
     */
    function cleanup(): void
    {
        _request = [];
        _session = [];
        _cookie = [];
        _response = null;
        _exception = null;
        _controller = null;
        _viewName = null;
        _layoutName = null;
        _requestSession = null;
        _securityToken = false;
        _csrfToken = false;
        _retainFlashMessages = false;
        _flashMessages = [];
    }

    /**
     * Calling this method will enable a SecurityComponent
     * compatible token to be added to request data. This
     * lets you easily test actions protected by SecurityComponent.
     *
     * @return void
     */
    function enableSecurityToken(): void
    {
        _securityToken = true;
    }

    /**
     * Set list of fields that are excluded from field validation.
     *
     * @param array<string> $unlockedFields List of fields that are excluded from field validation.
     * @return void
     */
    function setUnlockedFields(array $unlockedFields = []): void
    {
        _unlockedFields = $unlockedFields;
    }

    /**
     * Calling this method will add a CSRF token to the request.
     *
     * Both the POST data and cookie will be populated when this option
     * is enabled. The default parameter names will be used.
     *
     * @param string $cookieName The name of the csrf token cookie.
     * @return void
     */
    function enableCsrfToken(string $cookieName = "csrfToken"): void
    {
        _csrfToken = true;
        _csrfKeyName = $cookieName;
    }

    /**
     * Calling this method will re-store flash messages into the test session
     * after being removed by the FlashHelper
     *
     * @return void
     */
    function enableRetainFlashMessages(): void
    {
        _retainFlashMessages = true;
    }

    /**
     * Configures the data for the *next* request.
     *
     * This data is cleared in the tearDown() method.
     *
     * You can call this method multiple times to append into
     * the current state.
     * Sub-keys like "headers" will be reset, though.
     *
     * @param array $data The request data to use.
     * @return void
     */
    function configRequest(array $data): void
    {
        _request = $data + _request;
    }

    /**
     * Sets session data.
     *
     * This method lets you configure the session data
     * you want to be used for requests that follow. The session
     * state is reset in each tearDown().
     *
     * You can call this method multiple times to append into
     * the current state.
     *
     * @param array $data The session data to use.
     * @return void
     */
    function session(array $data): void
    {
        _session = $data + _session;
    }

    /**
     * Sets a request cookie for future requests.
     *
     * This method lets you configure the session data
     * you want to be used for requests that follow. The session
     * state is reset in each tearDown().
     *
     * You can call this method multiple times to append into
     * the current state.
     *
     * @param string $name The cookie name to use.
     * @param mixed $value The value of the cookie.
     * @return void
     */
    function cookie(string $name, $value): void
    {
        _cookie[$name] = $value;
    }

    /**
     * Returns the encryption key to be used.
     *
     * @return string
     */
    protected function _getCookieEncryptionKey(): string
    {
        return _cookieEncryptionKey ?? Security::getSalt();
    }

    /**
     * Sets a encrypted request cookie for future requests.
     *
     * The difference from cookie() is this encrypts the cookie
     * value like the CookieComponent.
     *
     * @param string $name The cookie name to use.
     * @param mixed $value The value of the cookie.
     * @param string|false $encrypt Encryption mode to use.
     * @param string|null $key Encryption key used. Defaults
     *   to Security.salt.
     * @return void
     * @see uim.cake.Utility\CookieCryptTrait::_encrypt()
     */
    function cookieEncrypted(string $name, $value, $encrypt = "aes", $key = null): void
    {
        _cookieEncryptionKey = $key;
        _cookie[$name] = _encrypt($value, $encrypt);
    }

    /**
     * Performs a GET request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @return void
     */
    function get($url): void
    {
        _sendRequest($url, "GET");
    }

    /**
     * Performs a POST request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @param array|string $data The data for the request.
     * @return void
     */
    function post($url, $data = []): void
    {
        _sendRequest($url, "POST", $data);
    }

    /**
     * Performs a PATCH request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @param array|string $data The data for the request.
     * @return void
     */
    function patch($url, $data = []): void
    {
        _sendRequest($url, "PATCH", $data);
    }

    /**
     * Performs a PUT request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @param array|string $data The data for the request.
     * @return void
     */
    function put($url, $data = []): void
    {
        _sendRequest($url, "PUT", $data);
    }

    /**
     * Performs a DELETE request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @return void
     */
    function delete($url): void
    {
        _sendRequest($url, "DELETE");
    }

    /**
     * Performs a HEAD request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @return void
     */
    function head($url): void
    {
        _sendRequest($url, "HEAD");
    }

    /**
     * Performs an OPTIONS request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string $url The URL to request.
     * @return void
     */
    function options($url): void
    {
        _sendRequest($url, "OPTIONS");
    }

    /**
     * Creates and send the request into a Dispatcher instance.
     *
     * Receives and stores the response for future inspection.
     *
     * @param array|string $url The URL
     * @param string $method The HTTP method
     * @param array|string $data The request data.
     * @return void
     * @throws \PHPUnit\Exception|\Throwable
     */
    protected function _sendRequest($url, $method, $data = []): void
    {
        $dispatcher = _makeDispatcher();
        $url = $dispatcher.resolveUrl($url);

        try {
            $request = _buildRequest($url, $method, $data);
            $response = $dispatcher.execute($request);
            _requestSession = $request["session"];
            if (_retainFlashMessages && _flashMessages) {
                _requestSession.write("Flash", _flashMessages);
            }
            _response = $response;
        } catch (PHPUnitException | DatabaseException $e) {
            throw $e;
        } catch (Throwable $e) {
            _exception = $e;
            // Simulate the global exception handler being invoked.
            _handleError($e);
        }
    }

    /**
     * Get the correct dispatcher instance.
     *
     * @return uim.cake.TestSuite\MiddlewareDispatcher A dispatcher instance
     */
    protected function _makeDispatcher(): MiddlewareDispatcher
    {
        EventManager::instance().on("Controller.initialize", [this, "controllerSpy"]);
        /** @var uim.cake.Core\IHttpApplication $app */
        $app = this.createApp();

        return new MiddlewareDispatcher($app);
    }

    /**
     * Adds additional event spies to the controller/view event manager.
     *
     * @param uim.cake.Event\IEvent $event A dispatcher event.
     * @param uim.cake.Controller\Controller|null $controller Controller instance.
     * @return void
     */
    function controllerSpy(IEvent $event, ?Controller $controller = null): void
    {
        if (!$controller) {
            /** @var uim.cake.controllers.Controller $controller */
            $controller = $event.getSubject();
        }
        _controller = $controller;
        $events = $controller.getEventManager();
        $flashCapture = function (IEvent $event): void {
            if (!_retainFlashMessages) {
                return;
            }
            $controller = $event.getSubject();
            _flashMessages = Hash::merge(
                _flashMessages,
                $controller.getRequest().getSession().read("Flash")
            );
        };
        $events.on("Controller.beforeRedirect", ["priority": -100], $flashCapture);
        $events.on("Controller.beforeRender", ["priority": -100], $flashCapture);
        $events.on("View.beforeRender", function ($event, $viewFile): void {
            if (!_viewName) {
                _viewName = $viewFile;
            }
        });
        $events.on("View.beforeLayout", function ($event, $viewFile): void {
            _layoutName = $viewFile;
        });
    }

    /**
     * Attempts to render an error response for a given exception.
     *
     * This method will attempt to use the configured exception renderer.
     * If that class does not exist, the built-in renderer will be used.
     *
     * @param \Throwable $exception Exception to handle.
     * @return void
     */
    protected function _handleError(Throwable $exception): void
    {
        $class = Configure::read("Error.exceptionRenderer");
        if (empty($class) || !class_exists($class)) {
            $class = WebExceptionRenderer::class;
        }
        /** @var uim.cake.Error\Renderer\WebExceptionRenderer $instance */
        $instance = new $class($exception);
        _response = $instance.render();
    }

    /**
     * Creates a request object with the configured options and parameters.
     *
     * @param string $url The URL
     * @param string $method The HTTP method
     * @param array|string $data The request data.
     * @return array The request context
     */
    protected function _buildRequest(string $url, $method, $data = []): array
    {
        $sessionConfig = (array)Configure::read("Session") + [
            "defaults": "php",
        ];
        $session = Session::create($sessionConfig);
        [$url, $query, $hostInfo] = _url($url);
        $tokenUrl = $url;

        if ($query) {
            $tokenUrl .= "?" . $query;
        }

        parse_str($query, $queryData);

        $env = [
            "REQUEST_METHOD": $method,
            "QUERY_STRING": $query,
            "REQUEST_URI": $url,
        ];
        if (!empty($hostInfo["ssl"])) {
            $env["HTTPS"] = "on";
        }
        if (isset($hostInfo["host"])) {
            $env["HTTP_HOST"] = $hostInfo["host"];
        }
        if (isset(_request["headers"])) {
            foreach (_request["headers"] as $k: $v) {
                $name = strtoupper(str_replace("-", "_", $k));
                if (!in_array($name, ["CONTENT_LENGTH", "CONTENT_TYPE"], true)) {
                    $name = "HTTP_" . $name;
                }
                $env[$name] = $v;
            }
            unset(_request["headers"]);
        }
        $props = [
            "url": $url,
            "session": $session,
            "query": $queryData,
            "files": [],
            "environment": $env,
        ];

        if (is_string($data)) {
            $props["input"] = $data;
        } elseif (
            is_array($data) &&
            isset($props["environment"]["CONTENT_TYPE"]) &&
            $props["environment"]["CONTENT_TYPE"] == "application/x-www-form-urlencoded"
        ) {
            $props["input"] = http_build_query($data);
        } else {
            $data = _addTokens($tokenUrl, $data);
            $props["post"] = _castToString($data);
        }

        $props["cookies"] = _cookie;
        $session.write(_session);

        return Hash::merge($props, _request);
    }

    /**
     * Add the CSRF and Security Component tokens if necessary.
     *
     * @param string $url The URL the form is being submitted on.
     * @param array $data The request body data.
     * @return array The request body with tokens added.
     */
    protected function _addTokens(string $url, array $data): array
    {
        if (_securityToken == true) {
            $fields = array_diff_key($data, array_flip(_unlockedFields));

            $keys = array_map(function ($field) {
                return preg_replace("/(\.\d+)+$/", "", $field);
            }, array_keys(Hash::flatten($fields)));

            $formProtector = new FormProtector(["unlockedFields": _unlockedFields]);
            foreach ($keys as $field) {
                $formProtector.addField($field);
            }
            $tokenData = $formProtector.buildTokenData($url, "cli");

            $data["_Token"] = $tokenData;
            $data["_Token"]["debug"] = "FormProtector debug data would be added here";
        }

        if (_csrfToken == true) {
            $middleware = new CsrfProtectionMiddleware();
            if (!isset(_cookie[_csrfKeyName]) && !isset(_session[_csrfKeyName])) {
                $token = $middleware.createToken();
            } elseif (isset(_cookie[_csrfKeyName])) {
                $token = _cookie[_csrfKeyName];
            } else {
                $token = _session[_csrfKeyName];
            }

            // Add the token to both the session and cookie to cover
            // both types of CSRF tokens. We generate the token with the cookie
            // middleware as cookie tokens will be accepted by session csrf, but not
            // the inverse.
            _session[_csrfKeyName] = $token;
            _cookie[_csrfKeyName] = $token;
            if (!isset($data["_csrfToken"])) {
                $data["_csrfToken"] = $token;
            }
        }

        return $data;
    }

    /**
     * Recursively casts all data to string as that is how data would be POSTed in
     * the real world
     *
     * @param array $data POST data
     * @return array
     */
    protected function _castToString(array $data): array
    {
        foreach ($data as $key: $value) {
            if (is_scalar($value)) {
                $data[$key] = $value == false ? "0" : (string)$value;

                continue;
            }

            if (is_array($value)) {
                $looksLikeFile = isset($value["error"], $value["tmp_name"], $value["size"]);
                if ($looksLikeFile) {
                    continue;
                }

                $data[$key] = _castToString($value);
            }
        }

        return $data;
    }

    /**
     * Creates a valid request url and parameter array more like Request::_url()
     *
     * @param string $url The URL
     * @return array Qualified URL, the query parameters, and host data
     */
    protected function _url(string $url): array
    {
        $uri = new Uri($url);
        $path = $uri.getPath();
        $query = $uri.getQuery();

        $hostData = [];
        if ($uri.getHost()) {
            $hostData["host"] = $uri.getHost();
        }
        if ($uri.getScheme()) {
            $hostData["ssl"] = $uri.getScheme() == "https";
        }

        return [$path, $query, $hostData];
    }

    /**
     * Get the response body as string
     *
     * @return string The response body.
     */
    protected function _getBodyAsString(): string
    {
        if (!_response) {
            this.fail("No response set, cannot assert content.");
        }

        return (string)_response.getBody();
    }

    /**
     * Fetches a view variable by name.
     *
     * If the view variable does not exist, null will be returned.
     *
     * @param string $name The view variable to get.
     * @return mixed The view variable if set.
     */
    function viewVariable(string $name) {
        return _controller ? _controller.viewBuilder().getVar($name) : null;
    }

    /**
     * Asserts that the response status code is in the 2xx range.
     *
     * @param string $message Custom message for failure.
     * @return void
     */
    function assertResponseOk(string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new StatusOk(_response), $verboseMessage);
    }

    /**
     * Asserts that the response status code is in the 2xx/3xx range.
     *
     * @param string $message Custom message for failure.
     * @return void
     */
    function assertResponseSuccess(string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new StatusSuccess(_response), $verboseMessage);
    }

    /**
     * Asserts that the response status code is in the 4xx range.
     *
     * @param string $message Custom message for failure.
     * @return void
     */
    function assertResponseError(string $message = ""): void
    {
        this.assertThat(null, new StatusError(_response), $message);
    }

    /**
     * Asserts that the response status code is in the 5xx range.
     *
     * @param string $message Custom message for failure.
     * @return void
     */
    function assertResponseFailure(string $message = ""): void
    {
        this.assertThat(null, new StatusFailure(_response), $message);
    }

    /**
     * Asserts a specific response status code.
     *
     * @param int $code Status code to assert.
     * @param string $message Custom message for failure.
     * @return void
     */
    function assertResponseCode(int $code, string $message = ""): void
    {
        this.assertThat($code, new StatusCode(_response), $message);
    }

    /**
     * Asserts that the Location header is correct. Comparison is made against a full URL.
     *
     * @param array|string|null $url The URL you expected the client to go to. This
     *   can either be a string URL or an array compatible with Router::url(). Use null to
     *   simply check for the existence of this header.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirect($url = null, $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, "Location"), $verboseMessage);

        if ($url) {
            this.assertThat(
                Router::url($url, true),
                new HeaderEquals(_response, "Location"),
                $verboseMessage
            );
        }
    }

    /**
     * Asserts that the Location header is correct. Comparison is made against exactly the URL provided.
     *
     * @param array|string|null $url The URL you expected the client to go to. This
     *   can either be a string URL or an array compatible with Router::url(). Use null to
     *   simply check for the existence of this header.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectEquals($url = null, $message = "") {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, "Location"), $verboseMessage);

        if ($url) {
            this.assertThat(Router::url($url), new HeaderEquals(_response, "Location"), $verboseMessage);
        }
    }

    /**
     * Asserts that the Location header contains a substring
     *
     * @param string $url The URL you expected the client to go to.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectContains(string $url, string $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, "Location"), $verboseMessage);
        this.assertThat($url, new HeaderContains(_response, "Location"), $verboseMessage);
    }

    /**
     * Asserts that the Location header does not contain a substring
     *
     * @param string $url The URL you expected the client to go to.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectNotContains(string $url, string $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, "Location"), $verboseMessage);
        this.assertThat($url, new HeaderNotContains(_response, "Location"), $verboseMessage);
    }

    /**
     * Asserts that the Location header is not set.
     *
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertNoRedirect(string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderNotSet(_response, "Location"), $verboseMessage);
    }

    /**
     * Asserts response headers
     *
     * @param string $header The header to check
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeader(string $header, string $content, string $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, $header), $verboseMessage);
        this.assertThat($content, new HeaderEquals(_response, $header), $verboseMessage);
    }

    /**
     * Asserts response header contains a string
     *
     * @param string $header The header to check
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeaderContains(string $header, string $content, string $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, $header), $verboseMessage);
        this.assertThat($content, new HeaderContains(_response, $header), $verboseMessage);
    }

    /**
     * Asserts response header does not contain a string
     *
     * @param string $header The header to check
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeaderNotContains(string $header, string $content, string $message = ""): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert header.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new HeaderSet(_response, $header), $verboseMessage);
        this.assertThat($content, new HeaderNotContains(_response, $header), $verboseMessage);
    }

    /**
     * Asserts content type
     *
     * @param string $type The content-type to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertContentType(string $type, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($type, new ContentType(_response), $verboseMessage);
    }

    /**
     * Asserts content in the response body equals.
     *
     * @param mixed $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseEquals($content, $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new BodyEquals(_response), $verboseMessage);
    }

    /**
     * Asserts content in the response body not equals.
     *
     * @param mixed $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotEquals($content, $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new BodyNotEquals(_response), $verboseMessage);
    }

    /**
     * Asserts content exists in the response body.
     *
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @param bool $ignoreCase A flag to check whether we should ignore case or not.
     * @return void
     */
    function assertResponseContains(string $content, string $message = "", bool $ignoreCase = false): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert content.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new BodyContains(_response, $ignoreCase), $verboseMessage);
    }

    /**
     * Asserts content does not exist in the response body.
     *
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @param bool $ignoreCase A flag to check whether we should ignore case or not.
     * @return void
     */
    function assertResponseNotContains(string $content, string $message = "", bool $ignoreCase = false): void
    {
        if (!_response) {
            this.fail("No response set, cannot assert content.");
        }

        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new BodyNotContains(_response, $ignoreCase), $verboseMessage);
    }

    /**
     * Asserts that the response body matches a given regular expression.
     *
     * @param string $pattern The pattern to compare against.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseRegExp(string $pattern, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($pattern, new BodyRegExp(_response), $verboseMessage);
    }

    /**
     * Asserts that the response body does not match a given regular expression.
     *
     * @param string $pattern The pattern to compare against.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotRegExp(string $pattern, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($pattern, new BodyNotRegExp(_response), $verboseMessage);
    }

    /**
     * Assert response content is not empty.
     *
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotEmpty(string $message = ""): void
    {
        this.assertThat(null, new BodyNotEmpty(_response), $message);
    }

    /**
     * Assert response content is empty.
     *
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseEmpty(string $message = ""): void
    {
        this.assertThat(null, new BodyEmpty(_response), $message);
    }

    /**
     * Asserts that the search string was in the template name.
     *
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertTemplate(string $content, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new TemplateFileEquals(_viewName), $verboseMessage);
    }

    /**
     * Asserts that the search string was in the layout name.
     *
     * @param string $content The content to check for.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertLayout(string $content, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($content, new LayoutFileEquals(_layoutName), $verboseMessage);
    }

    /**
     * Asserts session contents
     *
     * @param mixed $expected The expected contents.
     * @param string $path The session data path. Uses Hash::get() compatible notation
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSession($expected, string $path, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($expected, new SessionEquals($path), $verboseMessage);
    }

    /**
     * Asserts session key exists.
     *
     * @param string $path The session data path. Uses Hash::get() compatible notation.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSessionHasKey(string $path, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($path, new SessionHasKey($path), $verboseMessage);
    }

    /**
     * Asserts a session key does not exist.
     *
     * @param string $path The session data path. Uses Hash::get() compatible notation.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSessionNotHasKey(string $path, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($path, this.logicalNot(new SessionHasKey($path)), $verboseMessage);
    }

    /**
     * Asserts a flash message was set
     *
     * @param string $expected Expected message
     * @param string $key Flash key
     * @param string $message Assertion failure message
     * @return void
     */
    function assertFlashMessage(string $expected, string $key = "flash", string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($expected, new FlashParamEquals(_requestSession, $key, "message"), $verboseMessage);
    }

    /**
     * Asserts a flash message was set at a certain index
     *
     * @param int $at Flash index
     * @param string $expected Expected message
     * @param string $key Flash key
     * @param string $message Assertion failure message
     * @return void
     */
    function assertFlashMessageAt(int $at, string $expected, string $key = "flash", string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(
            $expected,
            new FlashParamEquals(_requestSession, $key, "message", $at),
            $verboseMessage
        );
    }

    /**
     * Asserts a flash element was set
     *
     * @param string $expected Expected element name
     * @param string $key Flash key
     * @param string $message Assertion failure message
     * @return void
     */
    function assertFlashElement(string $expected, string $key = "flash", string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(
            $expected,
            new FlashParamEquals(_requestSession, $key, "element"),
            $verboseMessage
        );
    }

    /**
     * Asserts a flash element was set at a certain index
     *
     * @param int $at Flash index
     * @param string $expected Expected element name
     * @param string $key Flash key
     * @param string $message Assertion failure message
     * @return void
     */
    function assertFlashElementAt(int $at, string $expected, string $key = "flash", string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(
            $expected,
            new FlashParamEquals(_requestSession, $key, "element", $at),
            $verboseMessage
        );
    }

    /**
     * Asserts cookie values
     *
     * @param mixed $expected The expected contents.
     * @param string $name The cookie name.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertCookie($expected, string $name, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($name, new CookieSet(_response), $verboseMessage);
        this.assertThat($expected, new CookieEquals(_response, $name), $verboseMessage);
    }

    /**
     * Asserts a cookie has not been set in the response
     *
     * @param string $cookie The cookie name to check
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertCookieNotSet(string $cookie, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($cookie, new CookieNotSet(_response), $verboseMessage);
    }

    /**
     * Disable the error handler middleware.
     *
     * By using this function, exceptions are no longer caught by the ErrorHandlerMiddleware
     * and are instead re-thrown by the TestExceptionRenderer. This can be helpful
     * when trying to diagnose/debug unexpected failures in test cases.
     *
     * @return void
     */
    function disableErrorHandlerMiddleware(): void
    {
        Configure::write("Error.exceptionRenderer", TestExceptionRenderer::class);
    }

    /**
     * Asserts cookie values which are encrypted by the
     * CookieComponent.
     *
     * The difference from assertCookie() is this decrypts the cookie
     * value like the CookieComponent for this assertion.
     *
     * @param mixed $expected The expected contents.
     * @param string $name The cookie name.
     * @param string $encrypt Encryption mode to use.
     * @param string|null $key Encryption key used. Defaults
     *   to Security.salt.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     * @see uim.cake.Utility\CookieCryptTrait::_encrypt()
     */
    function assertCookieEncrypted(
        $expected,
        string $name,
        string $encrypt = "aes",
        ?string $key = null,
        string $message = ""
    ): void {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat($name, new CookieSet(_response), $verboseMessage);

        _cookieEncryptionKey = $key;
        this.assertThat(
            $expected,
            new CookieEncryptedEquals(_response, $name, $encrypt, _getCookieEncryptionKey())
        );
    }

    /**
     * Asserts that a file with the given name was sent in the response
     *
     * @param string $expected The absolute file path that should be sent in the response.
     * @param string $message The failure message that will be appended to the generated message.
     * @return void
     */
    function assertFileResponse(string $expected, string $message = ""): void
    {
        $verboseMessage = this.extractVerboseMessage($message);
        this.assertThat(null, new FileSent(_response), $verboseMessage);
        this.assertThat($expected, new FileSentAs(_response), $verboseMessage);

        if (!_response) {
            return;
        }
        _response.getBody().close();
    }

    /**
     * Inspect controller to extract possible causes of the failed assertion
     *
     * @param string $message Original message to use as a base
     * @return string
     */
    protected function extractVerboseMessage(string $message): string
    {
        if (_exception instanceof Exception) {
            $message .= this.extractExceptionMessage(_exception);
        }
        if (_controller == null) {
            return $message;
        }
        $error = _controller.viewBuilder().getVar("error");
        if ($error instanceof Exception) {
            $message .= this.extractExceptionMessage(this.viewVariable("error"));
        }

        return $message;
    }

    /**
     * Extract verbose message for existing exception
     *
     * @param \Exception $exception Exception to extract
     * @return string
     */
    protected function extractExceptionMessage(Exception $exception): string
    {
        $exceptions = [$exception];
        $previous = $exception.getPrevious();
        while ($previous != null) {
            $exceptions[] = $previous;
            $previous = $previous.getPrevious();
        }
        $message = PHP_EOL;
        foreach ($exceptions as $i: $error) {
            if ($i == 0) {
                $message .= sprintf("Possibly related to %s: "%s"", get_class($error), $error.getMessage());
                $message .= PHP_EOL;
            } else {
                $message .= sprintf("Caused by %s: "%s"", get_class($error), $error.getMessage());
                $message .= PHP_EOL;
            }
            $message .= $error.getTraceAsString();
            $message .= PHP_EOL;
        }

        return $message;
    }

    /**
     * @return uim.cake.TestSuite\TestSession
     */
    protected function getSession(): TestSession
    {
        /** @psalm-suppress InvalidScalarArgument */
        return new TestSession($_SESSION);
    }
}
