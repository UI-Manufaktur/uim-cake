


 *


 * @since         0.10.0
  */module uim.cake.controllers.Component;

import uim.cake.auths.BaseAuthenticate;
import uim.cake.auths.BaseAuthorize;
import uim.cake.auths.Storage\IStorage;
import uim.cake.controllers.Component;
import uim.cake.controllers.Controller;
import uim.cake.core.App;
import uim.cake.core.exceptions.CakeException;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.events.EventInterface;
import uim.cake.http.exceptions.ForbiddenException;
import uim.cake.http.Response;
import uim.cake.http.ServerRequest;
import uim.cake.routings.Router;
import uim.cake.utilities.Hash;

/**
 * Authentication control component class.
 *
 * Binds access control with user authentication and session management.
 *
 * @property uim.cake.Controller\Component\RequestHandlerComponent $RequestHandler
 * @property uim.cake.Controller\Component\FlashComponent $Flash
 * @link https://book.cakephp.org/4/en/controllers/components/authentication.html
 * @deprecated 4.0.0 Use the cakephp/authentication and cakephp/authorization plugins instead.
 * @see https://github.com/cakephp/authentication
 * @see https://github.com/cakephp/authorization
 */
class AuthComponent : Component : EventDispatcherInterface
{
    use EventDispatcherTrait;

    /**
     * The query string key used for remembering the referred page when getting
     * redirected to login.
     *
     * @var string
     */
    const QUERY_STRING_REDIRECT = 'redirect';

    /**
     * Constant for 'all'
     *
     * @var string
     */
    const ALL = 'all';

    /**
     * Default config
     *
     * - `authenticate` - An array of authentication objects to use for authenticating users.
     *   You can configure multiple adapters and they will be checked sequentially
     *   when users are identified.
     *
     *   ```
     *   this.Auth.setConfig('authenticate', [
     *      'Form': [
     *         'userModel': 'Users.Users'
     *      ]
     *   ]);
     *   ```
     *
     *   Using the class name without 'Authenticate' as the key, you can pass in an
     *   array of config for each authentication object. Additionally, you can define
     *   config that should be set to all authentications objects using the 'all' key:
     *
     *   ```
     *   this.Auth.setConfig('authenticate', [
     *       AuthComponent::ALL: [
     *          'userModel': 'Users.Users',
     *          'scope': ['Users.active': 1]
     *      ],
     *     'Form',
     *     'Basic'
     *   ]);
     *   ```
     *
     * - `authorize` - An array of authorization objects to use for authorizing users.
     *   You can configure multiple adapters and they will be checked sequentially
     *   when authorization checks are done.
     *
     *   ```
     *   this.Auth.setConfig('authorize', [
     *      'Crud': [
     *          'actionPath': 'controllers/'
     *      ]
     *   ]);
     *   ```
     *
     *   Using the class name without 'Authorize' as the key, you can pass in an array
     *   of config for each authorization object. Additionally you can define config
     *   that should be set to all authorization objects using the AuthComponent::ALL key:
     *
     *   ```
     *   this.Auth.setConfig('authorize', [
     *      AuthComponent::ALL: [
     *          'actionPath': 'controllers/'
     *      ],
     *      'Crud',
     *      'CustomAuth'
     *   ]);
     *   ```
     *
     * - `flash` - Settings to use when Auth needs to do a flash message with
     *   FlashComponent::set(). Available keys are:
     *
     *   - `key` - The message domain to use for flashes generated by this component,
     *     defaults to 'auth'.
     *   - `element` - Flash element to use, defaults to 'default'.
     *   - `params` - The array of additional params to use, defaults to ['class': 'error']
     *
     * - `loginAction` - A URL (defined as a string or array) to the controller action
     *   that handles logins. Defaults to `/users/login`.
     *
     * - `loginRedirect` - Normally, if a user is redirected to the `loginAction` page,
     *   the location they were redirected from will be stored in the session so that
     *   they can be redirected back after a successful login. If this session value
     *   is not set, redirectUrl() method will return the URL specified in `loginRedirect`.
     *
     * - `logoutRedirect` - The default action to redirect to after the user is logged out.
     *   While AuthComponent does not handle post-logout redirection, a redirect URL
     *   will be returned from `AuthComponent::logout()`. Defaults to `loginAction`.
     *
     * - `authError` - Error to display when user attempts to access an object or
     *   action to which they do not have access.
     *
     * - `unauthorizedRedirect` - Controls handling of unauthorized access.
     *
     *   - For default value `true` unauthorized user is redirected to the referrer URL
     *     or `$loginRedirect` or '/'.
     *   - If set to a string or array the value is used as a URL to redirect to.
     *   - If set to false a `ForbiddenException` exception is thrown instead of redirecting.
     *
     * - `storage` - Storage class to use for persisting user record. When using
     *   stateless authenticator you should set this to 'Memory'. Defaults to 'Session'.
     *
     * - `checkAuthIn` - Name of event for which initial auth checks should be done.
     *   Defaults to 'Controller.startup'. You can set it to 'Controller.initialize'
     *   if you want the check to be done before controller's beforeFilter() is run.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'authenticate': null,
        'authorize': null,
        'flash': null,
        'loginAction': null,
        'loginRedirect': null,
        'logoutRedirect': null,
        'authError': null,
        'unauthorizedRedirect': true,
        'storage': 'Session',
        'checkAuthIn': 'Controller.startup',
    ];

    /**
     * Other components utilized by AuthComponent
     *
     * @var array
     */
    protected $components = ['RequestHandler', 'Flash'];

    /**
     * Objects that will be used for authentication checks.
     *
     * @var array<uim.cake.Auth\BaseAuthenticate>
     */
    protected $_authenticateObjects = [];

    /**
     * Objects that will be used for authorization checks.
     *
     * @var array<uim.cake.Auth\BaseAuthorize>
     */
    protected $_authorizeObjects = [];

    /**
     * Storage object.
     *
     * @var uim.cake.auths.Storage\IStorage|null
     */
    protected $_storage;

    /**
     * Controller actions for which user validation is not required.
     *
     * @var array<string>
     * @see uim.cake.controllers.components.AuthComponent::allow()
     */
    $allowedActions = [];

    /**
     * The instance of the Authenticate provider that was used for
     * successfully logging in the current user after calling `login()`
     * in the same request
     *
     * @var uim.cake.auths.BaseAuthenticate|null
     */
    protected $_authenticationProvider;

    /**
     * The instance of the Authorize provider that was used to grant
     * access to the current user to the URL they are requesting.
     *
     * @var uim.cake.auths.BaseAuthorize|null
     */
    protected $_authorizationProvider;

    /**
     * Initialize properties.
     *
     * @param array<string, mixed> $config The config data.
     */
    void initialize(array $config) {
        $controller = _registry.getController();
        this.setEventManager($controller.getEventManager());
    }

    /**
     * Callback for Controller.startup event.
     *
     * @param uim.cake.events.IEvent $event Event instance.
     * @return uim.cake.http.Response|null
     */
    function startup(IEvent $event): ?Response
    {
        return this.authCheck($event);
    }

    /**
     * Main execution method, handles initial authentication check and redirection
     * of invalid users.
     *
     * The auth check is done when event name is same as the one configured in
     * `checkAuthIn` config.
     *
     * @param uim.cake.events.IEvent $event Event instance.
     * @return uim.cake.http.Response|null
     * @throws \ReflectionException
     */
    function authCheck(IEvent $event): ?Response
    {
        if (_config['checkAuthIn'] != $event.getName()) {
            return null;
        }

        /** @var uim.cake.controllers.Controller $controller */
        $controller = $event.getSubject();

        $action = $controller.getRequest().getParam('action');
        if ($action == null || !$controller.isAction($action)) {
            return null;
        }

        _setDefaults();

        if (_isAllowed($controller)) {
            return null;
        }

        $isLoginAction = _isLoginAction($controller);

        if (!_getUser()) {
            if ($isLoginAction) {
                return null;
            }
            $result = _unauthenticated($controller);
            if ($result instanceof Response) {
                $event.stopPropagation();
            }

            return $result;
        }

        if (
            $isLoginAction ||
            empty(_config['authorize']) ||
            this.isAuthorized(this.user())
        ) {
            return null;
        }

        $event.stopPropagation();

        return _unauthorized($controller);
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [
            'Controller.initialize': 'authCheck',
            'Controller.startup': 'startup',
        ];
    }

    /**
     * Checks whether current action is accessible without authentication.
     *
     * @param uim.cake.controllers.Controller $controller A reference to the instantiating
     *   controller object
     * @return bool True if action is accessible without authentication else false
     */
    protected function _isAllowed(Controller $controller): bool
    {
        $action = strtolower($controller.getRequest().getParam('action', ''));

        return in_array($action, array_map('strtolower', this.allowedActions), true);
    }

    /**
     * Handles unauthenticated access attempt. First the `unauthenticated()` method
     * of the last authenticator in the chain will be called. The authenticator can
     * handle sending response or redirection as appropriate and return `true` to
     * indicate no further action is necessary. If authenticator returns null this
     * method redirects user to login action.
     *
     * @param uim.cake.controllers.Controller $controller A reference to the controller object.
     * @return uim.cake.http.Response|null Null if current action is login action
     *   else response object returned by authenticate object or Controller::redirect().
     * @throws uim.cake.Core\exceptions.CakeException
     */
    protected function _unauthenticated(Controller $controller): ?Response
    {
        if (empty(_authenticateObjects)) {
            this.constructAuthenticate();
        }
        $response = $controller.getResponse();
        $auth = end(_authenticateObjects);
        if ($auth == false) {
            throw new CakeException('At least one authenticate object must be available.');
        }
        $result = $auth.unauthenticated($controller.getRequest(), $response);
        if ($result != null) {
            return $result instanceof Response ? $result : null;
        }

        if (!$controller.getRequest().is('ajax')) {
            this.flash(_config['authError']);

            return $controller.redirect(_loginActionRedirectUrl());
        }

        return $response.withStatus(403);
    }

    /**
     * Returns the URL of the login action to redirect to.
     *
     * This includes the redirect query string if applicable.
     *
     * @return array|string
     */
    protected function _loginActionRedirectUrl() {
        $urlToRedirectBackTo = _getUrlToRedirectBackTo();

        $loginAction = _config['loginAction'];
        if ($urlToRedirectBackTo == '/') {
            return $loginAction;
        }

        if (is_array($loginAction)) {
            $loginAction['?'][static::QUERY_STRING_REDIRECT] = $urlToRedirectBackTo;
        } else {
            $char = strpos($loginAction, '?') == false ? '?' : '&';
            $loginAction .= $char . static::QUERY_STRING_REDIRECT . '=' . urlencode($urlToRedirectBackTo);
        }

        return $loginAction;
    }

    /**
     * Normalizes config `loginAction` and checks if current request URL is same as login action.
     *
     * @param uim.cake.controllers.Controller $controller A reference to the controller object.
     * @return bool True if current action is login action else false.
     */
    protected function _isLoginAction(Controller $controller): bool
    {
        $uri = $controller.getRequest().getUri();
        $url = Router::normalize($uri.getPath());
        $loginAction = Router::normalize(_config['loginAction']);

        return $loginAction == $url;
    }

    /**
     * Handle unauthorized access attempt
     *
     * @param uim.cake.controllers.Controller $controller A reference to the controller object
     * @return uim.cake.http.Response|null
     * @throws uim.cake.http.exceptions.ForbiddenException
     */
    protected function _unauthorized(Controller $controller): ?Response
    {
        if (_config['unauthorizedRedirect'] == false) {
            throw new ForbiddenException(_config['authError']);
        }

        this.flash(_config['authError']);
        if (_config['unauthorizedRedirect'] == true) {
            $default = '/';
            if (!empty(_config['loginRedirect'])) {
                $default = _config['loginRedirect'];
            }
            if (is_array($default)) {
                $default['_base'] = false;
            }
            $url = $controller.referer($default, true);
        } else {
            $url = _config['unauthorizedRedirect'];
        }

        return $controller.redirect($url);
    }

    /**
     * Sets defaults for configs.
     *
     */
    protected void _setDefaults() {
        $defaults = [
            'authenticate': ['Form'],
            'flash': [
                'element': 'error',
                'key': 'flash',
                'params': ['class': 'error'],
            ],
            'loginAction': [
                'controller': 'Users',
                'action': 'login',
                'plugin': null,
            ],
            'logoutRedirect': _config['loginAction'],
            'authError': __d('cake', 'You are not authorized to access that location.'),
        ];

        $config = this.getConfig();
        foreach ($config as $key: $value) {
            if ($value != null) {
                unset($defaults[$key]);
            }
        }
        this.setConfig($defaults);
    }

    /**
     * Check if the provided user is authorized for the request.
     *
     * Uses the configured Authorization adapters to check whether a user is authorized.
     * Each adapter will be checked in sequence, if any of them return true, then the user will
     * be authorized for the request.
     *
     * @param \ArrayAccess|array|null $user The user to check the authorization of.
     *   If empty the user fetched from storage will be used.
     * @param uim.cake.http.ServerRequest|null $request The request to authenticate for.
     *   If empty, the current request will be used.
     * @return bool True if $user is authorized, otherwise false
     */
    function isAuthorized($user = null, ?ServerRequest $request = null): bool
    {
        if (empty($user) && !this.user()) {
            return false;
        }
        if (empty($user)) {
            $user = this.user();
        }
        if (empty($request)) {
            $request = this.getController().getRequest();
        }
        if (empty(_authorizeObjects)) {
            this.constructAuthorize();
        }
        foreach (_authorizeObjects as $authorizer) {
            if ($authorizer.authorize($user, $request) == true) {
                _authorizationProvider = $authorizer;

                return true;
            }
        }

        return false;
    }

    /**
     * Loads the authorization objects configured.
     *
     * @return array|null The loaded authorization objects, or null when authorize is empty.
     * @throws uim.cake.Core\exceptions.CakeException
     */
    function constructAuthorize(): ?array
    {
        if (empty(_config['authorize'])) {
            return null;
        }
        _authorizeObjects = [];
        $authorize = Hash::normalize((array)_config['authorize']);
        $global = [];
        if (isset($authorize[AuthComponent::ALL])) {
            $global = $authorize[AuthComponent::ALL];
            unset($authorize[AuthComponent::ALL]);
        }
        foreach ($authorize as $alias: $config) {
            if (!empty($config['className'])) {
                $class = $config['className'];
                unset($config['className']);
            } else {
                $class = $alias;
            }
            $className = App::className($class, 'Auth', 'Authorize');
            if ($className == null) {
                throw new CakeException(sprintf('Authorization adapter "%s" was not found.', $class));
            }
            if (!method_exists($className, 'authorize')) {
                throw new CakeException('Authorization objects must implement an authorize() method.');
            }
            $config = (array)$config + $global;
            _authorizeObjects[$alias] = new $className(_registry, $config);
        }

        return _authorizeObjects;
    }

    /**
     * Getter for authorize objects. Will return a particular authorize object.
     *
     * @param string $alias Alias for the authorize object
     * @return uim.cake.Auth\BaseAuthorize|null
     */
    function getAuthorize(string $alias): ?BaseAuthorize
    {
        if (empty(_authorizeObjects)) {
            this.constructAuthorize();
        }

        return _authorizeObjects[$alias] ?? null;
    }

    /**
     * Takes a list of actions in the current controller for which authentication is not required, or
     * no parameters to allow all actions.
     *
     * You can use allow with either an array or a simple string.
     *
     * ```
     * this.Auth.allow('view');
     * this.Auth.allow(['edit', 'add']);
     * ```
     * or to allow all actions
     * ```
     * this.Auth.allow();
     * ```
     *
     * @param array<string>|string|null $actions Controller action name or array of actions
     * @return void
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#making-actions-public
     */
    void allow($actions = null) {
        if ($actions == null) {
            $controller = _registry.getController();
            this.allowedActions = get_class_methods($controller);

            return;
        }
        this.allowedActions = array_merge(this.allowedActions, (array)$actions);
    }

    /**
     * Removes items from the list of allowed/no authentication required actions.
     *
     * You can use deny with either an array or a simple string.
     *
     * ```
     * this.Auth.deny('view');
     * this.Auth.deny(['edit', 'add']);
     * ```
     * or
     * ```
     * this.Auth.deny();
     * ```
     * to remove all items from the allowed list
     *
     * @param array<string>|string|null $actions Controller action name or array of actions
     * @return void
     * @see uim.cake.controllers.components.AuthComponent::allow()
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#making-actions-require-authorization
     */
    void deny($actions = null) {
        if ($actions == null) {
            this.allowedActions = [];

            return;
        }
        foreach ((array)$actions as $action) {
            $i = array_search($action, this.allowedActions, true);
            if (is_int($i)) {
                unset(this.allowedActions[$i]);
            }
        }
        this.allowedActions = array_values(this.allowedActions);
    }

    /**
     * Set provided user info to storage as logged in user.
     *
     * The storage class is configured using `storage` config key or passing
     * instance to AuthComponent::storage().
     *
     * @param \ArrayAccess|array $user User data.
     * @return void
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#identifying-users-and-logging-them-in
     */
    void setUser($user) {
        this.storage().write($user);
    }

    /**
     * Log a user out.
     *
     * Returns the logout action to redirect to. Triggers the `Auth.logout` event
     * which the authenticate classes can listen for and perform custom logout logic.
     *
     * @return string Normalized config `logoutRedirect`
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#logging-users-out
     */
    function logout(): string
    {
        _setDefaults();
        if (empty(_authenticateObjects)) {
            this.constructAuthenticate();
        }
        $user = (array)this.user();
        this.dispatchEvent('Auth.logout', [$user]);
        this.storage().delete();

        return Router::normalize(_config['logoutRedirect']);
    }

    /**
     * Get the current user from storage.
     *
     * @param string|null $key Field to retrieve. Leave null to get entire User record.
     * @return mixed|null Either User record or null if no user is logged in, or retrieved field if key is specified.
     * @link https://book.cakephp.org/4/en/controllers/components/authentication.html#accessing-the-logged-in-user
     */
    function user(?string $key = null) {
        $user = this.storage().read();
        if (!$user) {
            return null;
        }

        if ($key == null) {
            return $user;
        }

        return Hash::get($user, $key);
    }

    /**
     * Similar to AuthComponent::user() except if user is not found in
     * configured storage, connected authentication objects will have their
     * getUser() methods called.
     *
     * This lets stateless authentication methods function correctly.
     *
     * @return bool true If a user can be found, false if one cannot.
     */
    protected function _getUser(): bool
    {
        $user = this.user();
        if ($user) {
            return true;
        }

        if (empty(_authenticateObjects)) {
            this.constructAuthenticate();
        }
        foreach (_authenticateObjects as $auth) {
            $result = $auth.getUser(this.getController().getRequest());
            if (!empty($result) && is_array($result)) {
                _authenticationProvider = $auth;
                $event = this.dispatchEvent('Auth.afterIdentify', [$result, $auth]);
                if ($event.getResult() != null) {
                    $result = $event.getResult();
                }
                this.storage().write($result);

                return true;
            }
        }

        return false;
    }

    /**
     * Get the URL a user should be redirected to upon login.
     *
     * Pass a URL in to set the destination a user should be redirected to upon
     * logging in.
     *
     * If no parameter is passed, gets the authentication redirect URL. The URL
     * returned is as per following rules:
     *
     *  - Returns the normalized redirect URL from storage if it is
     *    present and for the same domain the current app is running on.
     *  - If there is no URL returned from storage and there is a config
     *    `loginRedirect`, the `loginRedirect` value is returned.
     *  - If there is no session and no `loginRedirect`, / is returned.
     *
     * @param array|string|null $url Optional URL to write as the login redirect URL.
     * @return string Redirect URL
     */
    function redirectUrl($url = null): string
    {
        $redirectUrl = this.getController().getRequest().getQuery(static::QUERY_STRING_REDIRECT);
        if ($redirectUrl && (substr($redirectUrl, 0, 1) != '/' || substr($redirectUrl, 0, 2) == '//')) {
            $redirectUrl = null;
        }

        if ($url != null) {
            $redirectUrl = $url;
        } elseif ($redirectUrl) {
            if (
                _config['loginAction']
                && Router::normalize($redirectUrl) == Router::normalize(_config['loginAction'])
            ) {
                $redirectUrl = _config['loginRedirect'];
            }
        } elseif (_config['loginRedirect']) {
            $redirectUrl = _config['loginRedirect'];
        } else {
            $redirectUrl = '/';
        }
        if (is_array($redirectUrl)) {
            return Router::url($redirectUrl + ['_base': false]);
        }

        return $redirectUrl;
    }

    /**
     * Use the configured authentication adapters, and attempt to identify the user
     * by credentials contained in $request.
     *
     * Triggers `Auth.afterIdentify` event which the authenticate classes can listen
     * to.
     *
     * @return array|false User record data, or false, if the user could not be identified.
     */
    function identify() {
        _setDefaults();

        if (empty(_authenticateObjects)) {
            this.constructAuthenticate();
        }
        foreach (_authenticateObjects as $auth) {
            $result = $auth.authenticate(
                this.getController().getRequest(),
                this.getController().getResponse()
            );
            if (!empty($result)) {
                _authenticationProvider = $auth;
                $event = this.dispatchEvent('Auth.afterIdentify', [$result, $auth]);
                if ($event.getResult() != null) {
                    return $event.getResult();
                }

                return $result;
            }
        }

        return false;
    }

    /**
     * Loads the configured authentication objects.
     *
     * @return array<string, object>|null The loaded authorization objects, or null on empty authenticate value.
     * @throws uim.cake.Core\exceptions.CakeException
     */
    function constructAuthenticate(): ?array
    {
        if (empty(_config['authenticate'])) {
            return null;
        }
        _authenticateObjects = [];
        $authenticate = Hash::normalize((array)_config['authenticate']);
        $global = [];
        if (isset($authenticate[AuthComponent::ALL])) {
            $global = $authenticate[AuthComponent::ALL];
            unset($authenticate[AuthComponent::ALL]);
        }
        foreach ($authenticate as $alias: $config) {
            if (!empty($config['className'])) {
                $class = $config['className'];
                unset($config['className']);
            } else {
                $class = $alias;
            }
            $className = App::className($class, 'Auth', 'Authenticate');
            if ($className == null) {
                throw new CakeException(sprintf('Authentication adapter "%s" was not found.', $class));
            }
            if (!method_exists($className, 'authenticate')) {
                throw new CakeException('Authentication objects must implement an authenticate() method.');
            }
            $config = array_merge($global, (array)$config);
            _authenticateObjects[$alias] = new $className(_registry, $config);
            this.getEventManager().on(_authenticateObjects[$alias]);
        }

        return _authenticateObjects;
    }

    /**
     * Get/set user record storage object.
     *
     * @param uim.cake.Auth\Storage\IStorage|null $storage Sets provided
     *   object as storage or if null returns configured storage object.
     * @return uim.cake.Auth\Storage\IStorage|null
     */
    function storage(?IStorage $storage = null): ?IStorage
    {
        if ($storage != null) {
            _storage = $storage;

            return null;
        }

        if (_storage) {
            return _storage;
        }

        $config = _config['storage'];
        if (is_string($config)) {
            $class = $config;
            $config = [];
        } else {
            $class = $config['className'];
            unset($config['className']);
        }
        $className = App::className($class, 'Auth/Storage', 'Storage');
        if ($className == null) {
            throw new CakeException(sprintf('Auth storage adapter "%s" was not found.', $class));
        }
        $request = this.getController().getRequest();
        $response = this.getController().getResponse();
        /** @var uim.cake.auths.Storage\IStorage $storage */
        $storage = new $className($request, $response, $config);

        return _storage = $storage;
    }

    /**
     * Magic accessor for backward compatibility for property `$sessionKey`.
     *
     * @param string $name Property name
     * @return mixed
     */
    function __get(string $name) {
        if ($name == 'sessionKey') {
            return this.storage().getConfig('key');
        }

        return parent::__get($name);
    }

    /**
     * Magic setter for backward compatibility for property `$sessionKey`.
     *
     * @param string $name Property name.
     * @param mixed $value Value to set.
     */
    void __set(string $name, $value) {
        if ($name == 'sessionKey') {
            _storage = null;

            if ($value == false) {
                this.setConfig('storage', 'Memory');

                return;
            }

            this.setConfig('storage', 'Session');
            this.storage().setConfig('key', $value);

            return;
        }

        this.{$name} = $value;
    }

    /**
     * Getter for authenticate objects. Will return a particular authenticate object.
     *
     * @param string $alias Alias for the authenticate object
     * @return uim.cake.Auth\BaseAuthenticate|null
     */
    function getAuthenticate(string $alias): ?BaseAuthenticate
    {
        if (empty(_authenticateObjects)) {
            this.constructAuthenticate();
        }

        return _authenticateObjects[$alias] ?? null;
    }

    /**
     * Set a flash message. Uses the Flash component with values from `flash` config.
     *
     * @param string|false $message The message to set. False to skip.
     */
    void flash($message) {
        if ($message == false) {
            return;
        }

        this.Flash.set($message, _config['flash']);
    }

    /**
     * If login was called during this request and the user was successfully
     * authenticated, this function will return the instance of the authentication
     * object that was used for logging the user in.
     *
     * @return uim.cake.Auth\BaseAuthenticate|null
     */
    function authenticationProvider(): ?BaseAuthenticate
    {
        return _authenticationProvider;
    }

    /**
     * If there was any authorization processing for the current request, this function
     * will return the instance of the Authorization object that granted access to the
     * user to the current address.
     *
     * @return uim.cake.Auth\BaseAuthorize|null
     */
    function authorizationProvider(): ?BaseAuthorize
    {
        return _authorizationProvider;
    }

    /**
     * Returns the URL to redirect back to or / if not possible.
     *
     * This method takes the referrer into account if the
     * request is not of type GET.
     *
     */
    protected string _getUrlToRedirectBackTo(): string
    {
        $urlToRedirectBackTo = this.getController().getRequest().getRequestTarget();
        if (!this.getController().getRequest().is('get')) {
            $urlToRedirectBackTo = this.getController().referer();
        }

        return $urlToRedirectBackTo;
    }
}
