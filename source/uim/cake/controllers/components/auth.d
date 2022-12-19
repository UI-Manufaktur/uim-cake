/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.controllerss.components;

@safe:
import uim.cake;

/**
 * Authentication control component class.
 *
 * Binds access control with user authentication and session management.
 *
 * @property \Cake\Controller\Component\RequestHandlerComponent myRequestHandler
 * @property \Cake\Controller\Component\FlashComponent $Flash
 * @link https://book.UIM.org/4/en/controllers/components/authentication.html
 * @deprecated 4.0.0 Use the UIM/authentication and UIM/authorization plugins instead.
 * @see https://github.com/UIM/authentication
 * @see https://github.com/UIM/authorization
 */
class AuthComponent : Component : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The query string key used for remembering the referred page when getting
     * redirected to login.
     */
    public const string QUERY_STRING_REDIRECT = "redirect";

    /**
     * Constant for "all"
     */
    public const string ALL = "all";

    /**
     * Default config
     *
     * - `authenticate` - An array of authentication objects to use for authenticating users.
     *   You can configure multiple adapters and they will be checked sequentially
     *   when users are identified.
     *
     *   ```
     *   this.Auth.setConfig("authenticate", [
     *      "Form":[
     *         "userModel":"Users.Users"
     *      ]
     *   ]);
     *   ```
     *
     *   Using the class name without "Authenticate" as the key, you can pass in an
     *   array of config for each authentication object. Additionally, you can define
     *   config that should be set to all authentications objects using the "all" key:
     *
     *   ```
     *   this.Auth.setConfig("authenticate", [
     *       AuthComponent::ALL: [
     *          "userModel":"Users.Users",
     *          "scope":["Users.active":1]
     *      ],
     *     "Form",
     *     "Basic"
     *   ]);
     *   ```
     *
     * - `authorize` - An array of authorization objects to use for authorizing users.
     *   You can configure multiple adapters and they will be checked sequentially
     *   when authorization checks are done.
     *
     *   ```
     *   this.Auth.setConfig("authorize", [
     *      "Crud":[
     *          "actionPath":"controllers/"
     *      ]
     *   ]);
     *   ```
     *
     *   Using the class name without "Authorize" as the key, you can pass in an array
     *   of config for each authorization object. Additionally you can define config
     *   that should be set to all authorization objects using the AuthComponent::ALL key:
     *
     *   ```
     *   this.Auth.setConfig("authorize", [
     *      AuthComponent::ALL: [
     *          "actionPath":"controllers/"
     *      ],
     *      "Crud",
     *      "CustomAuth"
     *   ]);
     *   ```
     *
     * - `flash` - Settings to use when Auth needs to do a flash message with
     *   FlashComponent::set(). Available keys are:
     *
     *   - `key` - The message domain to use for flashes generated by this component,
     *     defaults to "auth".
     *   - `element` - Flash element to use, defaults to "default".
     *   - `params` - The array of additional params to use, defaults to ["class":"error"]
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
     *     or `$loginRedirect` or "/".
     *   - If set to a string or array the value is used as a URL to redirect to.
     *   - If set to false a `ForbiddenException` exception is thrown instead of redirecting.
     *
     * - `storage` - Storage class to use for persisting user record. When using
     *   stateless authenticator you should set this to "Memory". Defaults to "Session".
     *
     * - `checkAuthIn` - Name of event for which initial auth checks should be done.
     *   Defaults to "Controller.startup". You can set it to "Controller.initialize"
     *   if you want the check to be done before controller"s beforeFilter() is run.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "authenticate":null,
        "authorize":null,
        "flash":null,
        "loginAction":null,
        "loginRedirect":null,
        "logoutRedirect":null,
        "authError":null,
        "unauthorizedRedirect":true,
        "storage":"Session",
        "checkAuthIn":"Controller.startup",
    ];

    /**
     * Other components utilized by AuthComponent
     *
     * @var array
     */
    protected $components = ["RequestHandler", "Flash"];

    /**
     * Objects that will be used for authentication checks.
     *
     * @var array<\Cake\Auth\BaseAuthenticate>
     */
    protected $_authenticateObjects = [];

    /**
     * Objects that will be used for authorization checks.
     *
     * @var array<\Cake\Auth\BaseAuthorize>
     */
    protected $_authorizeObjects = [];

    /**
     * Storage object.
     *
     * @var \Cake\Auth\Storage\IStorage|null
     */
    protected $_storage;

    /**
     * Controller actions for which user validation is not required.
     *
     * @var array<string>
     * @see \Cake\Controller\Component\AuthComponent::allow()
     */
    public $allowedActions = [];

    /**
     * The instance of the Authenticate provider that was used for
     * successfully logging in the current user after calling `login()`
     * in the same request
     *
     * @var \Cake\Auth\BaseAuthenticate|null
     */
    protected $_authenticationProvider;

    /**
     * The instance of the Authorize provider that was used to grant
     * access to the current user to the URL they are requesting.
     *
     * @var \Cake\Auth\BaseAuthorize|null
     */
    protected $_authorizationProvider;

    /**
     * Initialize properties.
     *
     * @param array<string, mixed> myConfig The config data.
     */
    void initialize(array myConfig) {
        $controller = this._registry.getController();
        this.setEventManager($controller.getEventManager());
    }

    /**
     * Callback for Controller.startup event.
     *
     * @param \Cake\Event\IEvent myEvent Event instance.
     * @return \Cake\Http\Response|null
     */
    function startup(IEvent myEvent): ?Response
    {
        return this.authCheck(myEvent);
    }

    /**
     * Main execution method, handles initial authentication check and redirection
     * of invalid users.
     *
     * The auth check is done when event name is same as the one configured in
     * `checkAuthIn` config.
     *
     * @param \Cake\Event\IEvent myEvent Event instance.
     * @return \Cake\Http\Response|null
     * @throws \ReflectionException
     */
    function authCheck(IEvent myEvent): ?Response
    {
        if (this._config["checkAuthIn"] !== myEvent.getName()) {
            return null;
        }

        /** @var \Cake\Controller\Controller $controller */
        $controller = myEvent.getSubject();

        $action = $controller.getRequest().getParam("action");
        if ($action == null || !$controller.isAction($action)) {
            return null;
        }

        this._setDefaults();

        if (this._isAllowed($controller)) {
            return null;
        }

        $isLoginAction = this._isLoginAction($controller);

        if (!this._getUser()) {
            if ($isLoginAction) {
                return null;
            }
            myResult = this._unauthenticated($controller);
            if (myResult instanceof Response) {
                myEvent.stopPropagation();
            }

            return myResult;
        }

        if (
            $isLoginAction ||
            empty(this._config["authorize"]) ||
            this.isAuthorized(this.user())
        ) {
            return null;
        }

        myEvent.stopPropagation();

        return this._unauthorized($controller);
    }

    /**
     * Events supported by this component.
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [
            "Controller.initialize":"authCheck",
            "Controller.startup":"startup",
        ];
    }

    /**
     * Checks whether current action is accessible without authentication.
     *
     * @param \Cake\Controller\Controller $controller A reference to the instantiating
     *   controller object
     * @return bool True if action is accessible without authentication else false
     */
    protected bool _isAllowed(Controller $controller) {
        $action = strtolower($controller.getRequest().getParam("action", ""));

        return in_array($action, array_map("strtolower", this.allowedActions), true);
    }

    /**
     * Handles unauthenticated access attempt. First the `unauthenticated()` method
     * of the last authenticator in the chain will be called. The authenticator can
     * handle sending response or redirection as appropriate and return `true` to
     * indicate no further action is necessary. If authenticator returns null this
     * method redirects user to login action.
     *
     * @param \Cake\Controller\Controller $controller A reference to the controller object.
     * @return \Cake\Http\Response|null Null if current action is login action
     *   else response object returned by authenticate object or Controller::redirect().
     * @throws \Cake\Core\Exception\CakeException
     */
    protected auto _unauthenticated(Controller $controller): ?Response
    {
        if (empty(this._authenticateObjects)) {
            this.constructAuthenticate();
        }
        $response = $controller.getResponse();
        $auth = end(this._authenticateObjects);
        if ($auth == false) {
            throw new CakeException("At least one authenticate object must be available.");
        }
        myResult = $auth.unauthenticated($controller.getRequest(), $response);
        if (myResult !== null) {
            return myResult instanceof Response ? myResult : null;
        }

        if (!$controller.getRequest().is("ajax")) {
            this.flash(this._config["authError"]);

            return $controller.redirect(this._loginActionRedirectUrl());
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
    protected auto _loginActionRedirectUrl() {
        myUrlToRedirectBackTo = this._getUrlToRedirectBackTo();

        $loginAction = this._config["loginAction"];
        if (myUrlToRedirectBackTo == "/") {
            return $loginAction;
        }

        if (is_array($loginAction)) {
            $loginAction["?"][static::QUERY_STRING_REDIRECT] = myUrlToRedirectBackTo;
        } else {
            $char = indexOf($loginAction, "?") == false ? "?" : "&";
            $loginAction .= $char . static::QUERY_STRING_REDIRECT . "=" . urlencode(myUrlToRedirectBackTo);
        }

        return $loginAction;
    }

    /**
     * Normalizes config `loginAction` and checks if current request URL is same as login action.
     *
     * @param \Cake\Controller\Controller $controller A reference to the controller object.
     * @return bool True if current action is login action else false.
     */
    protected bool _isLoginAction(Controller $controller) {
        $uri = $controller.getRequest().getUri();
        myUrl = Router::normalize($uri.getPath());
        $loginAction = Router::normalize(this._config["loginAction"]);

        return $loginAction == myUrl;
    }

    /**
     * Handle unauthorized access attempt
     *
     * @param \Cake\Controller\Controller $controller A reference to the controller object
     * @return \Cake\Http\Response|null
     * @throws \Cake\Http\Exception\ForbiddenException
     */
    protected auto _unauthorized(Controller $controller): ?Response
    {
        if (this._config["unauthorizedRedirect"] == false) {
            throw new ForbiddenException(this._config["authError"]);
        }

        this.flash(this._config["authError"]);
        if (this._config["unauthorizedRedirect"] == true) {
            $default = "/";
            if (!empty(this._config["loginRedirect"])) {
                $default = this._config["loginRedirect"];
            }
            if (is_array($default)) {
                $default["_base"] = false;
            }
            myUrl = $controller.referer($default, true);
        } else {
            myUrl = this._config["unauthorizedRedirect"];
        }

        return $controller.redirect(myUrl);
    }

    /**
     * Sets defaults for configs.
     *
     */
    protected void _setDefaults() {
        $defaults = [
            "authenticate":["Form"],
            "flash":[
                "element":"error",
                "key":"flash",
                "params":["class":"error"],
            ],
            "loginAction":[
                "controller":"Users",
                "action":"login",
                "plugin":null,
            ],
            "logoutRedirect":this._config["loginAction"],
            "authError":__d("cake", "You are not authorized to access that location."),
        ];

        myConfig = this.getConfig();
        foreach (myConfig as myKey: myValue) {
            if (myValue !== null) {
                unset($defaults[myKey]);
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
     * @param \ArrayAccess|array|null myUser The user to check the authorization of.
     *   If empty the user fetched from storage will be used.
     * @param \Cake\Http\ServerRequest|null myRequest The request to authenticate for.
     *   If empty, the current request will be used.
     * @return bool True if myUser is authorized, otherwise false
     */
    bool isAuthorized(myUser = null, ?ServerRequest myRequest = null) {
        if (empty(myUser) && !this.user()) {
            return false;
        }
        if (empty(myUser)) {
            myUser = this.user();
        }
        if (empty(myRequest)) {
            myRequest = this.getController().getRequest();
        }
        if (empty(this._authorizeObjects)) {
            this.constructAuthorize();
        }
        foreach (this._authorizeObjects as $authorizer) {
            if ($authorizer.authorize(myUser, myRequest) == true) {
                this._authorizationProvider = $authorizer;

                return true;
            }
        }

        return false;
    }

    /**
     * Loads the authorization objects configured.
     *
     * @return array|null The loaded authorization objects, or null when authorize is empty.
     * @throws \Cake\Core\Exception\CakeException
     */
    function constructAuthorize(): ?array
    {
        if (empty(this._config["authorize"])) {
            return null;
        }
        this._authorizeObjects = [];
        $authorize = Hash::normalize((array)this._config["authorize"]);
        $global = [];
        if (isset($authorize[AuthComponent::ALL])) {
            $global = $authorize[AuthComponent::ALL];
            unset($authorize[AuthComponent::ALL]);
        }
        foreach ($authorize as myAlias: myConfig) {
            if (!empty(myConfig["className"])) {
                myClass = myConfig["className"];
                unset(myConfig["className"]);
            } else {
                myClass = myAlias;
            }
            myClassName = App::className(myClass, "Auth", "Authorize");
            if (myClassName == null) {
                throw new CakeException(sprintf("Authorization adapter "%s" was not found.", myClass));
            }
            if (!method_exists(myClassName, "authorize")) {
                throw new CakeException("Authorization objects must implement an authorize() method.");
            }
            myConfig = (array)myConfig + $global;
            this._authorizeObjects[myAlias] = new myClassName(this._registry, myConfig);
        }

        return this._authorizeObjects;
    }

    /**
     * Getter for authorize objects. Will return a particular authorize object.
     *
     * @param string myAlias Alias for the authorize object
     * @return \Cake\Auth\BaseAuthorize|null
     */
    auto getAuthorize(string myAlias): ?BaseAuthorize
    {
        if (empty(this._authorizeObjects)) {
            this.constructAuthorize();
        }

        return this._authorizeObjects[myAlias] ?? null;
    }

    /**
     * Takes a list of actions in the current controller for which authentication is not required, or
     * no parameters to allow all actions.
     *
     * You can use allow with either an array or a simple string.
     *
     * ```
     * this.Auth.allow("view");
     * this.Auth.allow(["edit", "add"]);
     * ```
     * or to allow all actions
     * ```
     * this.Auth.allow();
     * ```
     *
     * @param array<string>|string|null $actions Controller action name or array of actions
     * @link https://book.UIM.org/4/en/controllers/components/authentication.html#making-actions-public
     */
    void allow($actions = null) {
        if ($actions == null) {
            $controller = this._registry.getController();
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
     * this.Auth.deny("view");
     * this.Auth.deny(["edit", "add"]);
     * ```
     * or
     * ```
     * this.Auth.deny();
     * ```
     * to remove all items from the allowed list
     *
     * @param array<string>|string|null $actions Controller action name or array of actions
     * @see \Cake\Controller\Component\AuthComponent::allow()
     * @link https://book.UIM.org/4/en/controllers/components/authentication.html#making-actions-require-authorization
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
     * @param \ArrayAccess|array myUser User data.
     * @link https://book.UIM.org/4/en/controllers/components/authentication.html#identifying-users-and-logging-them-in
     */
    void setUser(myUser) {
        this.storage().write(myUser);
    }

    /**
     * Log a user out.
     *
     * Returns the logout action to redirect to. Triggers the `Auth.logout` event
     * which the authenticate classes can listen for and perform custom logout logic.
     *
     * @return string Normalized config `logoutRedirect`
     * @link https://book.UIM.org/4/en/controllers/components/authentication.html#logging-users-out
     */
    string logout() {
        this._setDefaults();
        if (empty(this._authenticateObjects)) {
            this.constructAuthenticate();
        }
        myUser = (array)this.user();
        this.dispatchEvent("Auth.logout", [myUser]);
        this.storage().delete();

        return Router::normalize(this._config["logoutRedirect"]);
    }

    /**
     * Get the current user from storage.
     *
     * @param string|null myKey Field to retrieve. Leave null to get entire User record.
     * @return mixed|null Either User record or null if no user is logged in, or retrieved field if key is specified.
     * @link https://book.UIM.org/4/en/controllers/components/authentication.html#accessing-the-logged-in-user
     */
    function user(Nullable!string myKey = null) {
        myUser = this.storage().read();
        if (!myUser) {
            return null;
        }

        if (myKey == null) {
            return myUser;
        }

        return Hash::get(myUser, myKey);
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
    protected bool _getUser() {
        myUser = this.user();
        if (myUser) {
            return true;
        }

        if (empty(this._authenticateObjects)) {
            this.constructAuthenticate();
        }
        foreach (this._authenticateObjects as $auth) {
            myResult = $auth.getUser(this.getController().getRequest());
            if (!empty(myResult) && is_array(myResult)) {
                this._authenticationProvider = $auth;
                myEvent = this.dispatchEvent("Auth.afterIdentify", [myResult, $auth]);
                if (myEvent.getResult() !== null) {
                    myResult = myEvent.getResult();
                }
                this.storage().write(myResult);

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
     * @param array|string|null myUrl Optional URL to write as the login redirect URL.
     * @return string Redirect URL
     */
    string redirectUrl(myUrl = null) {
        $redirectUrl = this.getController().getRequest().getQuery(static::QUERY_STRING_REDIRECT);
        if ($redirectUrl && (substr($redirectUrl, 0, 1) !== "/" || substr($redirectUrl, 0, 2) == "//")) {
            $redirectUrl = null;
        }

        if (myUrl !== null) {
            $redirectUrl = myUrl;
        } elseif ($redirectUrl) {
            if (
                this._config["loginAction"]
                && Router::normalize($redirectUrl) == Router::normalize(this._config["loginAction"])
            ) {
                $redirectUrl = this._config["loginRedirect"];
            }
        } elseif (this._config["loginRedirect"]) {
            $redirectUrl = this._config["loginRedirect"];
        } else {
            $redirectUrl = "/";
        }
        if (is_array($redirectUrl)) {
            return Router::url($redirectUrl + ["_base":false]);
        }

        return $redirectUrl;
    }

    /**
     * Use the configured authentication adapters, and attempt to identify the user
     * by credentials contained in myRequest.
     *
     * Triggers `Auth.afterIdentify` event which the authenticate classes can listen
     * to.
     *
     * @return array|false User record data, or false, if the user could not be identified.
     */
    function identify() {
        this._setDefaults();

        if (empty(this._authenticateObjects)) {
            this.constructAuthenticate();
        }
        foreach (this._authenticateObjects as $auth) {
            myResult = $auth.authenticate(
                this.getController().getRequest(),
                this.getController().getResponse()
            );
            if (!empty(myResult)) {
                this._authenticationProvider = $auth;
                myEvent = this.dispatchEvent("Auth.afterIdentify", [myResult, $auth]);
                if (myEvent.getResult() !== null) {
                    return myEvent.getResult();
                }

                return myResult;
            }
        }

        return false;
    }

    /**
     * Loads the configured authentication objects.
     *
     * @return array<string, object>|null The loaded authorization objects, or null on empty authenticate value.
     * @throws \Cake\Core\Exception\CakeException
     */
    function constructAuthenticate(): ?array
    {
        if (empty(this._config["authenticate"])) {
            return null;
        }
        this._authenticateObjects = [];
        $authenticate = Hash::normalize((array)this._config["authenticate"]);
        $global = [];
        if (isset($authenticate[AuthComponent::ALL])) {
            $global = $authenticate[AuthComponent::ALL];
            unset($authenticate[AuthComponent::ALL]);
        }
        foreach ($authenticate as myAlias: myConfig) {
            if (!empty(myConfig["className"])) {
                myClass = myConfig["className"];
                unset(myConfig["className"]);
            } else {
                myClass = myAlias;
            }
            myClassName = App::className(myClass, "Auth", "Authenticate");
            if (myClassName == null) {
                throw new CakeException(sprintf("Authentication adapter "%s" was not found.", myClass));
            }
            if (!method_exists(myClassName, "authenticate")) {
                throw new CakeException("Authentication objects must implement an authenticate() method.");
            }
            myConfig = array_merge($global, (array)myConfig);
            this._authenticateObjects[myAlias] = new myClassName(this._registry, myConfig);
            this.getEventManager().on(this._authenticateObjects[myAlias]);
        }

        return this._authenticateObjects;
    }

    /**
     * Get/set user record storage object.
     *
     * @param \Cake\Auth\Storage\IStorage|null $storage Sets provided
     *   object as storage or if null returns configured storage object.
     * @return \Cake\Auth\Storage\IStorage|null
     */
    function storage(?IStorage $storage = null): ?IStorage
    {
        if ($storage !== null) {
            this._storage = $storage;

            return null;
        }

        if (this._storage) {
            return this._storage;
        }

        myConfig = this._config["storage"];
        if (is_string(myConfig)) {
            myClass = myConfig;
            myConfig = [];
        } else {
            myClass = myConfig["className"];
            unset(myConfig["className"]);
        }
        myClassName = App::className(myClass, "Auth/Storage", "Storage");
        if (myClassName == null) {
            throw new CakeException(sprintf("Auth storage adapter "%s" was not found.", myClass));
        }
        myRequest = this.getController().getRequest();
        $response = this.getController().getResponse();
        /** @var \Cake\Auth\Storage\IStorage $storage */
        $storage = new myClassName(myRequest, $response, myConfig);

        return this._storage = $storage;
    }

    /**
     * Magic accessor for backward compatibility for property `$sessionKey`.
     *
     * @param string myName Property name
     * @return mixed
     */
    auto __get(string myName) {
        if (myName == "sessionKey") {
            return this.storage().getConfig("key");
        }

        return super.__get(myName);
    }

    /**
     * Magic setter for backward compatibility for property `$sessionKey`.
     *
     * @param string myName Property name.
     * @param mixed myValue Value to set.
     */
    void __set(string myName, myValue) {
        if (myName == "sessionKey") {
            this._storage = null;

            if (myValue == false) {
                this.setConfig("storage", "Memory");

                return;
            }

            this.setConfig("storage", "Session");
            this.storage().setConfig("key", myValue);

            return;
        }

        this.{myName} = myValue;
    }

    /**
     * Getter for authenticate objects. Will return a particular authenticate object.
     *
     * @param string myAlias Alias for the authenticate object
     * @return \Cake\Auth\BaseAuthenticate|null
     */
    auto getAuthenticate(string myAlias): ?BaseAuthenticate
    {
        if (empty(this._authenticateObjects)) {
            this.constructAuthenticate();
        }

        return this._authenticateObjects[myAlias] ?? null;
    }

    /**
     * Set a flash message. Uses the Flash component with values from `flash` config.
     *
     * @param string|false myMessage The message to set. False to skip.
     */
    void flash(myMessage) {
        if (myMessage == false) {
            return;
        }

        this.Flash.set(myMessage, this._config["flash"]);
    }

    /**
     * If login was called during this request and the user was successfully
     * authenticated, this function will return the instance of the authentication
     * object that was used for logging the user in.
     *
     * @return \Cake\Auth\BaseAuthenticate|null
     */
    function authenticationProvider(): ?BaseAuthenticate
    {
        return this._authenticationProvider;
    }

    /**
     * If there was any authorization processing for the current request, this function
     * will return the instance of the Authorization object that granted access to the
     * user to the current address.
     *
     * @return \Cake\Auth\BaseAuthorize|null
     */
    function authorizationProvider(): ?BaseAuthorize
    {
        return this._authorizationProvider;
    }

    /**
     * Returns the URL to redirect back to or / if not possible.
     *
     * This method takes the referrer into account if the
     * request is not of type GET.
     */
    protected string _getUrlToRedirectBackTo() {
        myUrlToRedirectBackTo = this.getController().getRequest().getRequestTarget();
        if (!this.getController().getRequest().is("get")) {
            myUrlToRedirectBackTo = this.getController().referer();
        }

        return myUrlToRedirectBackTo;
    }
}
