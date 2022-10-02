

/**

 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.controller\Controller;
import uim.cake.core.Configure;
import uim.cake.database.Exception\DatabaseException;
import uim.cake.Error\ExceptionRenderer;
import uim.cake.Event\IEvent;
import uim.cake.Event\EventManager;
import uim.cake.Form\FormProtector;
import uim.cake.Http\Middleware\CsrfProtectionMiddleware;
import uim.cake.Http\Session;
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
import uim.cake.Utility\CookieCryptTrait;
import uim.cake.Utility\Hash;
import uim.cake.Utility\Security;
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
     * @var \Cake\Controller\Controller|null
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
     * @var \Cake\Http\Session
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
    protected $_csrfKeyName = 'csrfToken';

    /**
     * Clears the state used for requests.
     *
     * @after
     * @return void
     * @psalm-suppress PossiblyNullPropertyAssignmentValue
     */
    function cleanup(): void
    {
        this._request = [];
        this._session = [];
        this._cookie = [];
        this._response = null;
        this._exception = null;
        this._controller = null;
        this._viewName = null;
        this._layoutName = null;
        this._requestSession = null;
        this._securityToken = false;
        this._csrfToken = false;
        this._retainFlashMessages = false;
        this._flashMessages = [];
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
        this._securityToken = true;
    }

    /**
     * Set list of fields that are excluded from field validation.
     *
     * @param array<string> $unlockedFields List of fields that are excluded from field validation.
     * @return void
     */
    auto setUnlockedFields(array $unlockedFields = []): void
    {
        this._unlockedFields = $unlockedFields;
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
    function enableCsrfToken(string $cookieName = 'csrfToken'): void
    {
        this._csrfToken = true;
        this._csrfKeyName = $cookieName;
    }

    /**
     * Calling this method will re-store flash messages into the test session
     * after being removed by the FlashHelper
     *
     * @return void
     */
    function enableRetainFlashMessages(): void
    {
        this._retainFlashMessages = true;
    }

    /**
     * Configures the data for the *next* request.
     *
     * This data is cleared in the tearDown() method.
     *
     * You can call this method multiple times to append into
     * the current state.
     *
     * @param array myData The request data to use.
     * @return void
     */
    function configRequest(array myData): void
    {
        this._request = myData + this._request;
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
     * @param array myData The session data to use.
     * @return void
     */
    function session(array myData): void
    {
        this._session = myData + this._session;
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
     * @param string myName The cookie name to use.
     * @param mixed myValue The value of the cookie.
     * @return void
     */
    function cookie(string myName, myValue): void
    {
        this._cookie[myName] = myValue;
    }

    /**
     * Returns the encryption key to be used.
     *
     * @return string
     */
    protected auto _getCookieEncryptionKey(): string
    {
        return this._cookieEncryptionKey ?? Security::getSalt();
    }

    /**
     * Sets a encrypted request cookie for future requests.
     *
     * The difference from cookie() is this encrypts the cookie
     * value like the CookieComponent.
     *
     * @param string myName The cookie name to use.
     * @param mixed myValue The value of the cookie.
     * @param string|false $encrypt Encryption mode to use.
     * @param string|null myKey Encryption key used. Defaults
     *   to Security.salt.
     * @return void
     * @see \Cake\Utility\CookieCryptTrait::_encrypt()
     */
    function cookieEncrypted(string myName, myValue, $encrypt = 'aes', myKey = null): void
    {
        this._cookieEncryptionKey = myKey;
        this._cookie[myName] = this._encrypt(myValue, $encrypt);
    }

    /**
     * Performs a GET request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @return void
     */
    auto get(myUrl): void
    {
        this._sendRequest(myUrl, 'GET');
    }

    /**
     * Performs a POST request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @param array|string myData The data for the request.
     * @return void
     */
    function post(myUrl, myData = []): void
    {
        this._sendRequest(myUrl, 'POST', myData);
    }

    /**
     * Performs a PATCH request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @param array|string myData The data for the request.
     * @return void
     */
    function patch(myUrl, myData = []): void
    {
        this._sendRequest(myUrl, 'PATCH', myData);
    }

    /**
     * Performs a PUT request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @param array|string myData The data for the request.
     * @return void
     */
    function put(myUrl, myData = []): void
    {
        this._sendRequest(myUrl, 'PUT', myData);
    }

    /**
     * Performs a DELETE request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @return void
     */
    function delete(myUrl): void
    {
        this._sendRequest(myUrl, 'DELETE');
    }

    /**
     * Performs a HEAD request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @return void
     */
    function head(myUrl): void
    {
        this._sendRequest(myUrl, 'HEAD');
    }

    /**
     * Performs an OPTIONS request using the current request data.
     *
     * The response of the dispatched request will be stored as
     * a property. You can use various assert methods to check the
     * response.
     *
     * @param array|string myUrl The URL to request.
     * @return void
     */
    function options(myUrl): void
    {
        this._sendRequest(myUrl, 'OPTIONS');
    }

    /**
     * Creates and send the request into a Dispatcher instance.
     *
     * Receives and stores the response for future inspection.
     *
     * @param array|string myUrl The URL
     * @param string $method The HTTP method
     * @param array|string myData The request data.
     * @return void
     * @throws \PHPUnit\Exception|\Throwable
     */
    protected auto _sendRequest(myUrl, $method, myData = []): void
    {
        $dispatcher = this._makeDispatcher();
        myUrl = $dispatcher.resolveUrl(myUrl);

        try {
            myRequest = this._buildRequest(myUrl, $method, myData);
            $response = $dispatcher.execute(myRequest);
            this._requestSession = myRequest['session'];
            if (this._retainFlashMessages && this._flashMessages) {
                this._requestSession.write('Flash', this._flashMessages);
            }
            this._response = $response;
        } catch (PHPUnitException | DatabaseException $e) {
            throw $e;
        } catch (Throwable $e) {
            this._exception = $e;
            // Simulate the global exception handler being invoked.
            this._handleError($e);
        }
    }

    /**
     * Get the correct dispatcher instance.
     *
     * @return \Cake\TestSuite\MiddlewareDispatcher A dispatcher instance
     */
    protected auto _makeDispatcher(): MiddlewareDispatcher
    {
        EventManager::instance().on('Controller.initialize', [this, 'controllerSpy']);
        /** @var \Cake\Core\HttpApplicationInterface $app */
        $app = this.createApp();

        return new MiddlewareDispatcher($app);
    }

    /**
     * Adds additional event spies to the controller/view event manager.
     *
     * @param \Cake\Event\IEvent myEvent A dispatcher event.
     * @param \Cake\Controller\Controller|null $controller Controller instance.
     * @return void
     */
    function controllerSpy(IEvent myEvent, ?Controller $controller = null): void
    {
        if (!$controller) {
            /** @var \Cake\Controller\Controller $controller */
            $controller = myEvent.getSubject();
        }
        this._controller = $controller;
        myEvents = $controller.getEventManager();
        $flashCapture = function (IEvent myEvent): void {
            if (!this._retainFlashMessages) {
                return;
            }
            $controller = myEvent.getSubject();
            this._flashMessages = Hash::merge(
                this._flashMessages,
                $controller.getRequest().getSession().read('Flash')
            );
        };
        myEvents.on('Controller.beforeRedirect', ['priority' => -100], $flashCapture);
        myEvents.on('Controller.beforeRender', ['priority' => -100], $flashCapture);
        myEvents.on('View.beforeRender', function (myEvent, $viewFile): void {
            if (!this._viewName) {
                this._viewName = $viewFile;
            }
        });
        myEvents.on('View.beforeLayout', function (myEvent, $viewFile): void {
            this._layoutName = $viewFile;
        });
    }

    /**
     * Attempts to render an error response for a given exception.
     *
     * This method will attempt to use the configured exception renderer.
     * If that class does not exist, the built-in renderer will be used.
     *
     * @param \Throwable myException Exception to handle.
     * @return void
     */
    protected auto _handleError(Throwable myException): void
    {
        myClass = Configure::read('Error.exceptionRenderer');
        if (empty(myClass) || !class_exists(myClass)) {
            myClass = ExceptionRenderer::class;
        }
        /** @var \Cake\Error\ExceptionRenderer $instance */
        $instance = new myClass(myException);
        this._response = $instance.render();
    }

    /**
     * Creates a request object with the configured options and parameters.
     *
     * @param string myUrl The URL
     * @param string $method The HTTP method
     * @param array|string myData The request data.
     * @return array The request context
     */
    protected auto _buildRequest(string myUrl, $method, myData = []): array
    {
        $sessionConfig = (array)Configure::read('Session') + [
            'defaults' => 'php',
        ];
        $session = Session::create($sessionConfig);
        [myUrl, myQuery, $hostInfo] = this._url(myUrl);
        $tokenUrl = myUrl;

        if (myQuery) {
            $tokenUrl .= '?' . myQuery;
        }

        parse_str(myQuery, myQueryData);

        $env = [
            'REQUEST_METHOD' => $method,
            'QUERY_STRING' => myQuery,
            'REQUEST_URI' => myUrl,
        ];
        if (!empty($hostInfo['ssl'])) {
            $env['HTTPS'] = 'on';
        }
        if (isset($hostInfo['host'])) {
            $env['HTTP_HOST'] = $hostInfo['host'];
        }
        if (isset(this._request['headers'])) {
            foreach (this._request['headers'] as $k => $v) {
                myName = strtoupper(str_replace('-', '_', $k));
                if (!in_array(myName, ['CONTENT_LENGTH', 'CONTENT_TYPE'], true)) {
                    myName = 'HTTP_' . myName;
                }
                $env[myName] = $v;
            }
            unset(this._request['headers']);
        }
        $props = [
            'url' => myUrl,
            'session' => $session,
            'query' => myQueryData,
            'files' => [],
            'environment' => $env,
        ];

        if (is_string(myData)) {
            $props['input'] = myData;
        } elseif (
            is_array(myData) &&
            isset($props['environment']['CONTENT_TYPE']) &&
            $props['environment']['CONTENT_TYPE'] === 'application/x-www-form-urlencoded'
        ) {
            $props['input'] = http_build_query(myData);
        } else {
            myData = this._addTokens($tokenUrl, myData);
            $props['post'] = this._castToString(myData);
        }

        $props['cookies'] = this._cookie;
        $session.write(this._session);
        $props = Hash::merge($props, this._request);

        return $props;
    }

    /**
     * Add the CSRF and Security Component tokens if necessary.
     *
     * @param string myUrl The URL the form is being submitted on.
     * @param array myData The request body data.
     * @return array The request body with tokens added.
     */
    protected auto _addTokens(string myUrl, array myData): array
    {
        if (this._securityToken === true) {
            myFields = array_diff_key(myData, array_flip(this._unlockedFields));

            myKeys = array_map(function (myField) {
                return preg_replace('/(\.\d+)+$/', '', myField);
            }, array_keys(Hash::flatten(myFields)));

            $formProtector = new FormProtector(['unlockedFields' => this._unlockedFields]);
            foreach (myKeys as myField) {
                $formProtector.addField(myField);
            }
            $tokenData = $formProtector.buildTokenData(myUrl, 'cli');

            myData['_Token'] = $tokenData;
            myData['_Token']['debug'] = 'FormProtector debug data would be added here';
        }

        if (this._csrfToken === true) {
            $middleware = new CsrfProtectionMiddleware();
            if (!isset(this._cookie[this._csrfKeyName]) && !isset(this._session[this._csrfKeyName])) {
                $token = $middleware.createToken();
            } elseif (isset(this._cookie[this._csrfKeyName])) {
                $token = this._cookie[this._csrfKeyName];
            } else {
                $token = this._session[this._csrfKeyName];
            }

            // Add the token to both the session and cookie to cover
            // both types of CSRF tokens. We generate the token with the cookie
            // middleware as cookie tokens will be accepted by session csrf, but not
            // the inverse.
            this._session[this._csrfKeyName] = $token;
            this._cookie[this._csrfKeyName] = $token;
            if (!isset(myData['_csrfToken'])) {
                myData['_csrfToken'] = $token;
            }
        }

        return myData;
    }

    /**
     * Recursively casts all data to string as that is how data would be POSTed in
     * the real world
     *
     * @param array myData POST data
     * @return array
     */
    protected auto _castToString(array myData): array
    {
        foreach (myData as myKey => myValue) {
            if (is_scalar(myValue)) {
                myData[myKey] = myValue === false ? '0' : (string)myValue;

                continue;
            }

            if (is_array(myValue)) {
                $looksLikeFile = isset(myValue['error'], myValue['tmp_name'], myValue['size']);
                if ($looksLikeFile) {
                    continue;
                }

                myData[myKey] = this._castToString(myValue);
            }
        }

        return myData;
    }

    /**
     * Creates a valid request url and parameter array more like Request::_url()
     *
     * @param string myUrl The URL
     * @return array Qualified URL, the query parameters, and host data
     */
    protected auto _url(string myUrl): array
    {
        $uri = new Uri(myUrl);
        myPath = $uri.getPath();
        myQuery = $uri.getQuery();

        $hostData = [];
        if ($uri.getHost()) {
            $hostData['host'] = $uri.getHost();
        }
        if ($uri.getScheme()) {
            $hostData['ssl'] = $uri.getScheme() === 'https';
        }

        return [myPath, myQuery, $hostData];
    }

    /**
     * Get the response body as string
     *
     * @return string The response body.
     */
    protected auto _getBodyAsString(): string
    {
        if (!this._response) {
            this.fail('No response set, cannot assert content.');
        }

        return (string)this._response.getBody();
    }

    /**
     * Fetches a view variable by name.
     *
     * If the view variable does not exist, null will be returned.
     *
     * @param string myName The view variable to get.
     * @return mixed The view variable if set.
     */
    function viewVariable(string myName)
    {
        return this._controller ? this._controller.viewBuilder().getVar(myName) : null;
    }

    /**
     * Asserts that the response status code is in the 2xx range.
     *
     * @param string myMessage Custom message for failure.
     * @return void
     */
    function assertResponseOk(string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new StatusOk(this._response), $verboseMessage);
    }

    /**
     * Asserts that the response status code is in the 2xx/3xx range.
     *
     * @param string myMessage Custom message for failure.
     * @return void
     */
    function assertResponseSuccess(string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new StatusSuccess(this._response), $verboseMessage);
    }

    /**
     * Asserts that the response status code is in the 4xx range.
     *
     * @param string myMessage Custom message for failure.
     * @return void
     */
    function assertResponseError(string myMessage = ''): void
    {
        this.assertThat(null, new StatusError(this._response), myMessage);
    }

    /**
     * Asserts that the response status code is in the 5xx range.
     *
     * @param string myMessage Custom message for failure.
     * @return void
     */
    function assertResponseFailure(string myMessage = ''): void
    {
        this.assertThat(null, new StatusFailure(this._response), myMessage);
    }

    /**
     * Asserts a specific response status code.
     *
     * @param int $code Status code to assert.
     * @param string myMessage Custom message for failure.
     * @return void
     */
    function assertResponseCode(int $code, string myMessage = ''): void
    {
        this.assertThat($code, new StatusCode(this._response), myMessage);
    }

    /**
     * Asserts that the Location header is correct. Comparison is made against a full URL.
     *
     * @param array|string|null myUrl The URL you expected the client to go to. This
     *   can either be a string URL or an array compatible with Router::url(). Use null to
     *   simply check for the existence of this header.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirect(myUrl = null, myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, 'Location'), $verboseMessage);

        if (myUrl) {
            this.assertThat(
                Router::url(myUrl, true),
                new HeaderEquals(this._response, 'Location'),
                $verboseMessage
            );
        }
    }

    /**
     * Asserts that the Location header is correct. Comparison is made against exactly the URL provided.
     *
     * @param array|string|null myUrl The URL you expected the client to go to. This
     *   can either be a string URL or an array compatible with Router::url(). Use null to
     *   simply check for the existence of this header.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectEquals(myUrl = null, myMessage = '')
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, 'Location'), $verboseMessage);

        if (myUrl) {
            this.assertThat(Router::url(myUrl), new HeaderEquals(this._response, 'Location'), $verboseMessage);
        }
    }

    /**
     * Asserts that the Location header contains a substring
     *
     * @param string myUrl The URL you expected the client to go to.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectContains(string myUrl, string myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, 'Location'), $verboseMessage);
        this.assertThat(myUrl, new HeaderContains(this._response, 'Location'), $verboseMessage);
    }

    /**
     * Asserts that the Location header does not contain a substring
     *
     * @param string myUrl The URL you expected the client to go to.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertRedirectNotContains(string myUrl, string myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, 'Location'), $verboseMessage);
        this.assertThat(myUrl, new HeaderNotContains(this._response, 'Location'), $verboseMessage);
    }

    /**
     * Asserts that the Location header is not set.
     *
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertNoRedirect(string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderNotSet(this._response, 'Location'), $verboseMessage);
    }

    /**
     * Asserts response headers
     *
     * @param string $header The header to check
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeader(string $header, string myContents, string myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, $header), $verboseMessage);
        this.assertThat(myContents, new HeaderEquals(this._response, $header), $verboseMessage);
    }

    /**
     * Asserts response header contains a string
     *
     * @param string $header The header to check
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeaderContains(string $header, string myContents, string myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, $header), $verboseMessage);
        this.assertThat(myContents, new HeaderContains(this._response, $header), $verboseMessage);
    }

    /**
     * Asserts response header does not contain a string
     *
     * @param string $header The header to check
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertHeaderNotContains(string $header, string myContents, string myMessage = ''): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert header.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new HeaderSet(this._response, $header), $verboseMessage);
        this.assertThat(myContents, new HeaderNotContains(this._response, $header), $verboseMessage);
    }

    /**
     * Asserts content type
     *
     * @param string myType The content-type to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertContentType(string myType, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myType, new ContentType(this._response), $verboseMessage);
    }

    /**
     * Asserts content in the response body equals.
     *
     * @param mixed myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseEquals(myContents, myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new BodyEquals(this._response), $verboseMessage);
    }

    /**
     * Asserts content in the response body not equals.
     *
     * @param mixed myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotEquals(myContents, myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new BodyNotEquals(this._response), $verboseMessage);
    }

    /**
     * Asserts content exists in the response body.
     *
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @param bool $ignoreCase A flag to check whether we should ignore case or not.
     * @return void
     */
    function assertResponseContains(string myContents, string myMessage = '', bool $ignoreCase = false): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert content.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new BodyContains(this._response, $ignoreCase), $verboseMessage);
    }

    /**
     * Asserts content does not exist in the response body.
     *
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @param bool $ignoreCase A flag to check whether we should ignore case or not.
     * @return void
     */
    function assertResponseNotContains(string myContents, string myMessage = '', bool $ignoreCase = false): void
    {
        if (!this._response) {
            this.fail('No response set, cannot assert content.');
        }

        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new BodyNotContains(this._response, $ignoreCase), $verboseMessage);
    }

    /**
     * Asserts that the response body matches a given regular expression.
     *
     * @param string $pattern The pattern to compare against.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseRegExp(string $pattern, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat($pattern, new BodyRegExp(this._response), $verboseMessage);
    }

    /**
     * Asserts that the response body does not match a given regular expression.
     *
     * @param string $pattern The pattern to compare against.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotRegExp(string $pattern, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat($pattern, new BodyNotRegExp(this._response), $verboseMessage);
    }

    /**
     * Assert response content is not empty.
     *
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseNotEmpty(string myMessage = ''): void
    {
        this.assertThat(null, new BodyNotEmpty(this._response), myMessage);
    }

    /**
     * Assert response content is empty.
     *
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertResponseEmpty(string myMessage = ''): void
    {
        this.assertThat(null, new BodyEmpty(this._response), myMessage);
    }

    /**
     * Asserts that the search string was in the template name.
     *
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertTemplate(string myContents, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new TemplateFileEquals(this._viewName), $verboseMessage);
    }

    /**
     * Asserts that the search string was in the layout name.
     *
     * @param string myContents The content to check for.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertLayout(string myContents, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myContents, new LayoutFileEquals(this._layoutName), $verboseMessage);
    }

    /**
     * Asserts session contents
     *
     * @param mixed $expected The expected contents.
     * @param string myPath The session data path. Uses Hash::get() compatible notation
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSession($expected, string myPath, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat($expected, new SessionEquals(myPath), $verboseMessage);
    }

    /**
     * Asserts session key exists.
     *
     * @param string myPath The session data path. Uses Hash::get() compatible notation.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSessionHasKey(string myPath, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myPath, new SessionHasKey(myPath), $verboseMessage);
    }

    /**
     * Asserts a session key does not exist.
     *
     * @param string myPath The session data path. Uses Hash::get() compatible notation.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertSessionNotHasKey(string myPath, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myPath, this.logicalNot(new SessionHasKey(myPath)), $verboseMessage);
    }

    /**
     * Asserts a flash message was set
     *
     * @param string $expected Expected message
     * @param string myKey Flash key
     * @param string myMessage Assertion failure message
     * @return void
     */
    function assertFlashMessage(string $expected, string myKey = 'flash', string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat($expected, new FlashParamEquals(this._requestSession, myKey, 'message'), $verboseMessage);
    }

    /**
     * Asserts a flash message was set at a certain index
     *
     * @param int $at Flash index
     * @param string $expected Expected message
     * @param string myKey Flash key
     * @param string myMessage Assertion failure message
     * @return void
     */
    function assertFlashMessageAt(int $at, string $expected, string myKey = 'flash', string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(
            $expected,
            new FlashParamEquals(this._requestSession, myKey, 'message', $at),
            $verboseMessage
        );
    }

    /**
     * Asserts a flash element was set
     *
     * @param string $expected Expected element name
     * @param string myKey Flash key
     * @param string myMessage Assertion failure message
     * @return void
     */
    function assertFlashElement(string $expected, string myKey = 'flash', string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(
            $expected,
            new FlashParamEquals(this._requestSession, myKey, 'element'),
            $verboseMessage
        );
    }

    /**
     * Asserts a flash element was set at a certain index
     *
     * @param int $at Flash index
     * @param string $expected Expected element name
     * @param string myKey Flash key
     * @param string myMessage Assertion failure message
     * @return void
     */
    function assertFlashElementAt(int $at, string $expected, string myKey = 'flash', string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(
            $expected,
            new FlashParamEquals(this._requestSession, myKey, 'element', $at),
            $verboseMessage
        );
    }

    /**
     * Asserts cookie values
     *
     * @param mixed $expected The expected contents.
     * @param string myName The cookie name.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertCookie($expected, string myName, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myName, new CookieSet(this._response), $verboseMessage);
        this.assertThat($expected, new CookieEquals(this._response, myName), $verboseMessage);
    }

    /**
     * Asserts a cookie has not been set in the response
     *
     * @param string $cookie The cookie name to check
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertCookieNotSet(string $cookie, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat($cookie, new CookieNotSet(this._response), $verboseMessage);
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
        Configure.write('Error.exceptionRenderer', TestExceptionRenderer::class);
    }

    /**
     * Asserts cookie values which are encrypted by the
     * CookieComponent.
     *
     * The difference from assertCookie() is this decrypts the cookie
     * value like the CookieComponent for this assertion.
     *
     * @param mixed $expected The expected contents.
     * @param string myName The cookie name.
     * @param string $encrypt Encryption mode to use.
     * @param string|null myKey Encryption key used. Defaults
     *   to Security.salt.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     * @see \Cake\Utility\CookieCryptTrait::_encrypt()
     */
    function assertCookieEncrypted(
        $expected,
        string myName,
        string $encrypt = 'aes',
        ?string myKey = null,
        string myMessage = ''
    ): void {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(myName, new CookieSet(this._response), $verboseMessage);

        this._cookieEncryptionKey = myKey;
        this.assertThat(
            $expected,
            new CookieEncryptedEquals(this._response, myName, $encrypt, this._getCookieEncryptionKey())
        );
    }

    /**
     * Asserts that a file with the given name was sent in the response
     *
     * @param string $expected The absolute file path that should be sent in the response.
     * @param string myMessage The failure message that will be appended to the generated message.
     * @return void
     */
    function assertFileResponse(string $expected, string myMessage = ''): void
    {
        $verboseMessage = this.extractVerboseMessage(myMessage);
        this.assertThat(null, new FileSent(this._response), $verboseMessage);
        this.assertThat($expected, new FileSentAs(this._response), $verboseMessage);
    }

    /**
     * Inspect controller to extract possible causes of the failed assertion
     *
     * @param string myMessage Original message to use as a base
     * @return string
     */
    protected auto extractVerboseMessage(string myMessage): string
    {
        if (this._exception instanceof Exception) {
            myMessage .= this.extractExceptionMessage(this._exception);
        }
        if (this._controller === null) {
            return myMessage;
        }
        myError = this._controller.viewBuilder().getVar('error');
        if (myError instanceof Exception) {
            myMessage .= this.extractExceptionMessage(this.viewVariable('error'));
        }

        return myMessage;
    }

    /**
     * Extract verbose message for existing exception
     *
     * @param \Exception myException Exception to extract
     * @return string
     */
    protected auto extractExceptionMessage(Exception myException): string
    {
        return PHP_EOL .
            sprintf('Possibly related to %s: "%s" ', get_class(myException), myException.getMessage()) .
            PHP_EOL .
            myException.getTraceAsString();
    }

    /**
     * @return \Cake\TestSuite\TestSession
     */
    protected auto getSession(): TestSession
    {
        return new TestSession($_SESSION);
    }
}
