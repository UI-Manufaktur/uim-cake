/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.controllers.controller;

@safe:
import uim.cake;

use Closure;
use InvalidArgumentException;
use Psr\Http\messages.IResponse;
use ReflectionClass;
use ReflectionException;
use ReflectionMethod;
use RuntimeException;
use UnexpectedValueException;

/**
 * Application controller class for organization of business logic.
 * Provides basic functionality, such as rendering views inside layouts,
 * automatic model availability, redirection, callbacks, and more.
 *
 * Controllers should provide a number of "action" methods. These are public
 * methods on a controller that are not inherited from `Controller`.
 * Each action serves as an endpoint for performing a specific action on a
 * resource or collection of resources. For example adding or editing a new
 * object, or listing a set of objects.
 *
 * You can access request parameters, using `this.getRequest()`. The request object
 * contains all the POST, GET and FILES that were part of the request.
 *
 * After performing the required action, controllers are responsible for
 * creating a response. This usually takes the form of a generated `View`, or
 * possibly a redirection to another URL. In either case `this.getResponse()`
 * allows you to manipulate all aspects of the response.
 *
 * Controllers are created based on request parameters and
 * routing. By default controllers and actions use conventional names.
 * For example `/posts/index` maps to `PostsController::index()`. You can re-map
 * URLs using Router::connect() or RouteBuilder::connect().
 *
 * ### Life cycle callbacks
 *
 * CakePHP fires a number of life cycle callbacks during each request.
 * By implementing a method you can receive the related events. The available
 * callbacks are:
 *
 * - `beforeFilter(IEvent $event)`
 *   Called before each action. This is a good place to do general logic that
 *   applies to all actions.
 * - `beforeRender(IEvent $event)`
 *   Called before the view is rendered.
 * - `beforeRedirect(IEvent $event, $url, Response $response)`
 *    Called before a redirect is done.
 * - `afterFilter(IEvent $event)`
 *   Called after each action is complete and after the view is rendered.
 *
 * @property uim.cake.Controller\Component\FlashComponent $Flash
 * @property uim.cake.Controller\Component\FormProtectionComponent $FormProtection
 * @property uim.cake.Controller\Component\PaginatorComponent $Paginator
 * @property uim.cake.Controller\Component\RequestHandlerComponent $RequestHandler
 * @property uim.cake.Controller\Component\SecurityComponent $Security
 * @property uim.cake.Controller\Component\AuthComponent $Auth
 * @link https://book.cakephp.org/4/en/controllers.html
 */
#[\AllowDynamicProperties]
class Controller : IEventListener, IEventDispatcher {
    use EventDispatcherTrait;
    use LocatorAwareTrait;
    use LogTrait;
    use ModelAwareTrait;
    use ViewVarsTrait;

    /**
     * The name of this controller. Controller names are plural, named after the model they manipulate.
     * Set automatically using conventions in Controller::__construct().
     */
    protected string aName;

    /**
     * An instance of a uim.cake.Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var uim.cake.http.ServerRequest
     * @link https://book.cakephp.org/4/en/controllers/request-response.html#request
     */
    protected $request;

    /**
     * An instance of a Response object that contains information about the impending response
     *
     * @link https://book.cakephp.org/4/en/controllers/request-response.html#response
     */
    protected uim.cake.http.Response $response;

    /**
     * Settings for pagination.
     *
     * Used to pre-configure pagination preferences for the various
     * tables your controller will be paginating.
     *
     * @var array
     * @see uim.cake.datasources.Paging\NumericPaginator
     */
    $paginate = [];

    /**
     * Set to true to automatically render the view
     * after action logic.
     */
    protected bool $autoRender = true;

    /**
     * Instance of ComponentRegistry used to create Components
     *
     * @var uim.cake.controllers.ComponentRegistry|null
     */
    protected $_components;

    /**
     * Automatically set to the name of a plugin.
     *
     * @var string|null
     */
    protected $plugin;

    /**
     * Middlewares list.
     *
     * @var array
     * @psalm-var array<int, array{middleware:\Psr\Http\servers.IMiddleware|\Closure|string, options:array{only?: array|string, except?: array|string}}>
     */
    protected $middlewares = [];

    /**
     * Constructor.
     *
     * Sets a number of properties based on conventions if they are empty. To override the
     * conventions CakePHP uses you can define properties in your class declaration.
     *
     * @param uim.cake.http.ServerRequest|null $request Request object for this controller. Can be null for testing,
     *   but expect that features that use the request parameters will not work.
     * @param uim.cake.http.Response|null $response Response object for this controller.
     * @param string|null $name Override the name useful in testing when using mocks.
     * @param uim.cake.events.IEventManager|null $eventManager The event manager. Defaults to a new instance.
     * @param uim.cake.controllers.ComponentRegistry|null $components The component registry. Defaults to a new instance.
     */
    this(
        ?ServerRequest $request = null,
        ?Response $response = null,
        ?string aName = null,
        ?IEventManager $eventManager = null,
        ?ComponentRegistry $components = null
    ) {
        if ($name != null) {
            this.name = $name;
        } elseif (this.name == null && $request) {
            this.name = $request.getParam("controller");
        }

        if (this.name == null) {
            [, $name] = namespaceSplit(static::class);
            this.name = substr($name, 0, -10);
        }

        this.setRequest($request ?: new ServerRequest());
        this.response = $response ?: new Response();

        if ($eventManager != null) {
            this.setEventManager($eventManager);
        }

        this.modelFactory("Table", [this.getTableLocator(), "get"]);

        if (this.defaultTable != null) {
            this.modelClass = this.defaultTable;
        }

        if (this.modelClass == null) {
            $plugin = this.request.getParam("plugin");
            $modelClass = ($plugin ? $plugin ~ "." : "") . this.name;
            _setModelClass($modelClass);

            this.defaultTable = $modelClass;
        }

        if ($components != null) {
            this.components($components);
        }

        this.initialize();

        if (isset(this.components)) {
            triggerWarning(
                "Support for loading components using $components property is removed~ " ~
                "Use this.loadComponent() instead in initialize()."
            );
        }

        if (isset(this.helpers)) {
            triggerWarning(
                "Support for loading helpers using $helpers property is removed~ " ~
                "Use this.viewBuilder().setHelpers() instead."
            );
        }

        this.getEventManager().on(this);
    }

    /**
     * Initialization hook method.
     *
     * Implement this method to avoid having to overwrite
     * the constructor and call parent.
     */
    void initialize() {
    }

    /**
     * Get the component registry for this controller.
     *
     * If called with the first parameter, it will be set as the controller _components property
     *
     * @param uim.cake.controllers.ComponentRegistry|null $components Component registry.
     * @return uim.cake.controllers.ComponentRegistry
     */
    function components(?ComponentRegistry $components = null): ComponentRegistry
    {
        if ($components != null) {
            $components.setController(this);

            return _components = $components;
        }

        if (_components == null) {
            _components = new ComponentRegistry(this);
        }

        return _components;
    }

    /**
     * Add a component to the controller"s registry.
     *
     * This method will also set the component to a property.
     * For example:
     *
     * ```
     * this.loadComponent("Authentication.Authentication");
     * ```
     *
     * Will result in a `Authentication` property being set.
     *
     * @param string aName The name of the component to load.
     * @param array<string, mixed> $config The config for the component.
     * @return uim.cake.controllers.Component
     * @throws \Exception
     */
    function loadComponent(string aName, array $config = []): Component
    {
        [, $prop] = pluginSplit($name);

        return this.{$prop} = this.components().load($name, $config);
    }

    /**
     * Magic accessor for model autoloading.
     *
     * @param string aName Property name
     * @return uim.cake.Datasource\RepositoryInterface|null The model instance or null
     */
    function __get(string aName) {
        if (!empty(this.modelClass)) {
            if (strpos(this.modelClass, "\\") == false) {
                [, $class] = pluginSplit(this.modelClass, true);
            } else {
                $class = App::shortName(this.modelClass, "Model/Table", "Table");
            }

            if ($class == $name) {
                return this.loadModel();
            }
        }

        $trace = debug_backtrace();
        $parts = explode("\\", static::class);
        trigger_error(
            sprintf(
                "Undefined property: %s::$%s in %s on line %s",
                array_pop($parts),
                $name,
                $trace[0]["file"],
                $trace[0]["line"]
            ),
            E_USER_NOTICE
        );

        return null;
    }

    /**
     * Magic setter for removed properties.
     *
     * @param string aName Property name.
     * @param mixed $value Value to set.
     */
    void __set(string aName, $value) {
        if ($name == "components") {
            triggerWarning(
                "Support for loading components using $components property is removed~ " ~
                "Use this.loadComponent() instead in initialize()."
            );

            return;
        }

        if ($name == "helpers") {
            triggerWarning(
                "Support for loading helpers using $helpers property is removed~ " ~
                "Use this.viewBuilder().setHelpers() instead."
            );

            return;
        }

        this.{$name} = $value;
    }

    /**
     * Returns the controller name.
     *
     * @return string

     */
    string getName() {
        return this.name;
    }

    /**
     * Sets the controller name.
     *
     * @param string aName Controller name.
     * @return this

     */
    function setName(string aName) {
        this.name = $name;

        return this;
    }

    /**
     * Returns the plugin name.
     *
     * @return string|null

     */
    Nullable!string getPlugin()
    {
        return this.plugin;
    }

    /**
     * Sets the plugin name.
     *
     * @param string|null $name Plugin name.
     * @return this

     */
    function setPlugin(?string aName) {
        this.plugin = $name;

        return this;
    }

    /**
     * Returns true if an action should be rendered automatically.
     *
     * @return bool

     */
    bool isAutoRenderEnabled() {
        return this.autoRender;
    }

    /**
     * Enable automatic action rendering.
     *
     * @return this

     */
    function enableAutoRender() {
        this.autoRender = true;

        return this;
    }

    /**
     * Disable automatic action rendering.
     *
     * @return this

     */
    function disableAutoRender() {
        this.autoRender = false;

        return this;
    }

    /**
     * Gets the request instance.
     *
     * @return uim.cake.http.ServerRequest

     */
    function getRequest(): ServerRequest
    {
        return this.request;
    }

    /**
     * Sets the request objects and configures a number of controller properties
     * based on the contents of the request. Controller acts as a proxy for certain View variables
     * which must also be updated here. The properties that get set are:
     *
     * - this.request - To the $request parameter
     *
     * @param uim.cake.http.ServerRequest $request Request instance.
     * @return this
     */
    function setRequest(ServerRequest $request) {
        this.request = $request;
        this.plugin = $request.getParam("plugin") ?: null;

        return this;
    }

    /**
     * Gets the response instance.
     *
     * @return uim.cake.http.Response

     */
    function getResponse(): Response
    {
        return this.response;
    }

    /**
     * Sets the response instance.
     *
     * @param uim.cake.http.Response $response Response instance.
     * @return this

     */
    function setResponse(Response $response) {
        this.response = $response;

        return this;
    }

    /**
     * Get the closure for action to be invoked by ControllerFactory.
     *
     * @return \Closure
     * @throws uim.cake.controllers.exceptions.MissingActionException
     */
    function getAction(): Closure
    {
        $request = this.request;
        $action = $request.getParam("action");

        if (!this.isAction($action)) {
            throw new MissingActionException([
                "controller": this.name ~ "Controller",
                "action": $request.getParam("action"),
                "prefix": $request.getParam("prefix") ?: "",
                "plugin": $request.getParam("plugin"),
            ]);
        }

        return Closure::fromCallable([this, $action]);
    }

    /**
     * Dispatches the controller action.
     *
     * @param \Closure $action The action closure.
     * @param array $args The arguments to be passed when invoking action.
     * @return void
     * @throws \UnexpectedValueException If return value of action is not `null` or `IResponse` instance.
     */
    void invokeAction(Closure $action, array $args) {
        $result = $action(...$args);
        if ($result != null && !$result instanceof IResponse) {
            throw new UnexpectedValueException(sprintf(
                "Controller actions can only return IResponse instance or null~ "
                ~ "Got %s instead.",
                getTypeName($result)
            ));
        }
        if ($result == null && this.isAutoRenderEnabled()) {
            $result = this.render();
        }
        if ($result) {
            this.response = $result;
        }
    }

    /**
     * Register middleware for the controller.
     *
     * @param \Psr\Http\servers.IMiddleware|\Closure|string $middleware Middleware.
     * @param array<string, mixed> $options Valid options:
     *  - `only`: (array|string) Only run the middleware for specified actions.
     *  - `except`: (array|string) Run the middleware for all actions except the specified ones.
     * @return void
     * @since 4.3.0
     * @psalm-param array{only?: array|string, except?: array|string} $options
     */
    function middleware($middleware, array $options = []) {
        this.middlewares[] = [
            "middleware": $middleware,
            "options": $options,
        ];
    }

    /**
     * Get middleware to be applied for this controller.
     *
     * @return array
     * @since 4.3.0
     */
    array getMiddleware() {
        $matching = [];
        $action = this.request.getParam("action");

        foreach (this.middlewares as $middleware) {
            $options = $middleware["options"];
            if (!empty($options["only"])) {
                if (in_array($action, (array)$options["only"], true)) {
                    $matching[] = $middleware["middleware"];
                }

                continue;
            }

            if (
                !empty($options["except"]) &&
                in_array($action, (array)$options["except"], true)
            ) {
                continue;
            }

            $matching[] = $middleware["middleware"];
        }

        return $matching;
    }

    /**
     * Returns a list of all events that will fire in the controller during its lifecycle.
     * You can override this function to add your own listener callbacks
     *
     * @return array<string, mixed>
     */
    array implementedEvents() {
        return [
            "Controller.initialize": "beforeFilter",
            "Controller.beforeRender": "beforeRender",
            "Controller.beforeRedirect": "beforeRedirect",
            "Controller.shutdown": "afterFilter",
        ];
    }

    /**
     * Perform the startup process for this controller.
     * Fire the Components and Controller callbacks in the correct order.
     *
     * - Initializes components, which fires their `initialize` callback
     * - Calls the controller `beforeFilter`.
     * - triggers Component `startup` methods.
     *
     * @return \Psr\Http\messages.IResponse|null
     */
    function startupProcess(): ?IResponse
    {
        $event = this.dispatchEvent("Controller.initialize");
        if ($event.getResult() instanceof IResponse) {
            return $event.getResult();
        }
        $event = this.dispatchEvent("Controller.startup");
        if ($event.getResult() instanceof IResponse) {
            return $event.getResult();
        }

        return null;
    }

    /**
     * Perform the various shutdown processes for this controller.
     * Fire the Components and Controller callbacks in the correct order.
     *
     * - triggers the component `shutdown` callback.
     * - calls the Controller"s `afterFilter` method.
     *
     * @return \Psr\Http\messages.IResponse|null
     */
    function shutdownProcess(): ?IResponse
    {
        $event = this.dispatchEvent("Controller.shutdown");
        if ($event.getResult() instanceof IResponse) {
            return $event.getResult();
        }

        return null;
    }

    /**
     * Redirects to given $url, after turning off this.autoRender.
     *
     * @param \Psr\Http\messages.UriInterface|array|string $url A string, array-based URL or UriInterface instance.
     * @param int $status HTTP status code. Defaults to `302`.
     * @return uim.cake.http.Response|null
     * @link https://book.cakephp.org/4/en/controllers.html#Controller::redirect
     */
    function redirect($url, int $status = 302): ?Response
    {
        this.autoRender = false;

        if ($status) {
            this.response = this.response.withStatus($status);
        }

        $event = this.dispatchEvent("Controller.beforeRedirect", [$url, this.response]);
        if ($event.getResult() instanceof Response) {
            return this.response = $event.getResult();
        }
        if ($event.isStopped()) {
            return null;
        }
        $response = this.response;

        if (!$response.getHeaderLine("Location")) {
            $response = $response.withLocation(Router::url($url, true));
        }

        return this.response = $response;
    }

    /**
     * Internally redirects one action to another. Does not perform another HTTP request unlike Controller::redirect()
     *
     * Examples:
     *
     * ```
     * setAction("another_action");
     * setAction("action_with_parameters", $parameter1);
     * ```
     *
     * @param string $action The new action to be "redirected" to.
     *   Any other parameters passed to this method will be passed as parameters to the new action.
     * @param mixed ...$args Arguments passed to the action
     * @return mixed Returns the return value of the called action
     * @deprecated 4.2.0 Refactor your code use `redirect()` instead of forwarding actions.
     */
    function setAction(string $action, ...$args) {
        deprecationWarning(
            "Controller::setAction() is deprecated. Either refactor your code to use `redirect()`, " ~
            "or call the other action as a method."
        );
        this.setRequest(this.request.withParam("action", $action));

        return this.$action(...$args);
    }

    /**
     * Instantiates the correct view class, hands it its data, and uses it to render the view output.
     *
     * @param string|null $template Template to use for rendering
     * @param string|null $layout Layout to use
     * @return uim.cake.http.Response A response object containing the rendered view.
     * @link https://book.cakephp.org/4/en/controllers.html#rendering-a-view
     */
    function render(?string $template = null, ?string $layout = null): Response
    {
        $builder = this.viewBuilder();
        if (!$builder.getTemplatePath()) {
            $builder.setTemplatePath(_templatePath());
        }

        this.autoRender = false;

        if ($template != null) {
            $builder.setTemplate($template);
        }

        if ($layout != null) {
            $builder.setLayout($layout);
        }

        $event = this.dispatchEvent("Controller.beforeRender");
        if ($event.getResult() instanceof Response) {
            return $event.getResult();
        }
        if ($event.isStopped()) {
            return this.response;
        }

        if ($builder.getTemplate() == null) {
            $builder.setTemplate(this.request.getParam("action"));
        }
        $viewClass = this.chooseViewClass();
        $view = this.createView($viewClass);

        $contents = $view.render();
        $response = $view.getResponse().withStringBody($contents);

        return this.setResponse($response).response;
    }

    /**
     * Get the View classes this controller can perform content negotiation with.
     *
     * Each view class must implement the `getContentType()` hook method
     * to participate in negotiation.
     *
     * @see Cake\Http\ContentTypeNegotiation
     * @return array<string>
     */
    string[] viewClasses() {
        return [];
    }

    /**
     * Use the view classes defined on this controller to view
     * selection based on content-type negotiation.
     *
     * @return string|null The chosen view class or null for no decision.
     */
    protected Nullable!string chooseViewClass()
    {
        $possibleViewClasses = this.viewClasses();
        if (empty($possibleViewClasses)) {
            return null;
        }
        // Controller or component has already made a view class decision.
        // That decision should overwrite the framework behavior.
        if (this.viewBuilder().getClassName() != null) {
            return null;
        }

        $typeMap = [];
        foreach ($possibleViewClasses as $class) {
            $viewContentType = $class::contentType();
            if ($viewContentType && !isset($typeMap[$viewContentType])) {
                $typeMap[$viewContentType] = $class;
            }
        }
        $request = this.getRequest();

        // Prefer the _ext route parameter if it is defined.
        $ext = $request.getParam("_ext");
        if ($ext) {
            $extTypes = (array)(this.response.getMimeType($ext) ?: []);
            foreach ($extTypes as $extType) {
                if (isset($typeMap[$extType])) {
                    return $typeMap[$extType];
                }
            }

            throw new NotFoundException();
        }

        // Use accept header based negotiation.
        $contentType = new ContentTypeNegotiation();
        $preferredType = $contentType.preferredType($request, array_keys($typeMap));
        if ($preferredType) {
            return $typeMap[$preferredType];
        }

        // Use the match-all view if available or null for no decision.
        return $typeMap[View::TYPE_MATCH_ALL] ?? null;
    }

    /**
     * Get the templatePath based on controller name and request prefix.
     */
    protected string _templatePath() {
        $templatePath = this.name;
        if (this.request.getParam("prefix")) {
            $prefixes = array_map(
                "Cake\Utility\Inflector::camelize",
                explode("/", this.request.getParam("prefix"))
            );
            $templatePath = implode(DIRECTORY_SEPARATOR, $prefixes) . DIRECTORY_SEPARATOR . $templatePath;
        }

        return $templatePath;
    }

    /**
     * Returns the referring URL for this request.
     *
     * @param array|string|null $default Default URL to use if HTTP_REFERER cannot be read from headers
     * @param bool $local If false, do not restrict referring URLs to local server.
     *   Careful with trusting external sources.
     * @return string Referring URL
     */
    string referer($default = "/", bool $local = true) {
        $referer = this.request.referer($local);
        if ($referer == null) {
            $url = Router::url($default, !$local);
            $base = this.request.getAttribute("base");
            if ($local && $base && strpos($url, $base) == 0) {
                $url = substr($url, strlen($base));
                if ($url[0] != "/") {
                    $url = "/" ~ $url;
                }

                return $url;
            }

            return $url;
        }

        return $referer;
    }

    /**
     * Handles pagination of records in Table objects.
     *
     * Will load the referenced Table object, and have the paginator
     * paginate the query using the request date and settings defined in `this.paginate`.
     *
     * This method will also make the PaginatorHelper available in the view.
     *
     * @param uim.cake.orm.Table|uim.cake.orm.Query|string|null $object Table to paginate
     * (e.g: Table instance, "TableName" or a Query object)
     * @param array<string, mixed> $settings The settings/configuration used for pagination.
     * @return uim.cake.orm.ResultSet|uim.cake.Datasource\IResultSet Query results
     * @link https://book.cakephp.org/4/en/controllers.html#paginating-a-model
     * @throws \RuntimeException When no compatible table object can be found.
     */
    function paginate($object = null, array $settings = []) {
        if (is_object($object)) {
            $table = $object;
        }

        if (is_string($object) || $object == null) {
            $try = [$object, this.modelClass];
            foreach ($try as $tableName) {
                if (empty($tableName)) {
                    continue;
                }
                $table = this.loadModel($tableName);
                break;
            }
        }

        if (empty($table)) {
            throw new RuntimeException("Unable to locate an object compatible with paginate.");
        }

        $settings += this.paginate;

        if (isset(this.Paginator)) {
            return this.Paginator.paginate($table, $settings);
        }

        if (isset($settings["paginator"])) {
            $settings["className"] = $settings["paginator"];
            deprecationWarning(
                "`paginator` option is deprecated,"
                ~ " use `className` instead a specify a paginator name/FQCN."
            );
        }

        $paginator = $settings["className"] ?? NumericPaginator::class;
        unset($settings["className"]);
        if (is_string($paginator)) {
            $className = App::className($paginator, "Datasource/Paging", "Paginator");
            if ($className == null) {
                throw new InvalidArgumentException("Invalid paginator: " ~ $paginator);
            }
            $paginator = new $className();
        }
        if (!$paginator instanceof PaginatorInterface) {
            throw new InvalidArgumentException("Paginator must be an instance of " ~ PaginatorInterface::class);
        }

        $results = null;
        try {
            $results = $paginator.paginate(
                $table,
                this.request.getQueryParams(),
                $settings
            );
        } catch (PageOutOfBoundsException $e) {
            // Exception thrown below
        } finally {
            $paging = $paginator.getPagingParams() + (array)this.request.getAttribute("paging", []);
            this.request = this.request.withAttribute("paging", $paging);
        }

        if (isset($e)) {
            throw new NotFoundException(null, null, $e);
        }

        /** @psalm-suppress NullableReturnStatement */
        return $results;
    }

    /**
     * Method to check that an action is accessible from a URL.
     *
     * Override this method to change which controller methods can be reached.
     * The default implementation disallows access to all methods defined on Cake\Controller\Controller,
     * and allows all methods on all subclasses of this class.
     *
     * @param string $action The action to check.
     * @return bool Whether the method is accessible from a URL.
     * @throws \ReflectionException
     */
    bool isAction(string $action) {
        $baseClass = new ReflectionClass(self::class);
        if ($baseClass.hasMethod($action)) {
            return false;
        }
        try {
            $method = new ReflectionMethod(this, $action);
        } catch (ReflectionException $e) {
            return false;
        }

        return $method.isPublic() && $method.getName() == $action;
    }

    /**
     * Called before the controller action. You can use this method to configure and customize components
     * or perform logic that needs to happen before each controller action.
     *
     * @param uim.cake.events.IEvent $event An Event instance
     * @return uim.cake.http.Response|null|void
     * @link https://book.cakephp.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeFilter(IEvent $event) {
    }

    /**
     * Called after the controller action is run, but before the view is rendered. You can use this method
     * to perform logic or set view variables that are required on every request.
     *
     * @param uim.cake.events.IEvent $event An Event instance
     * @return uim.cake.http.Response|null|void
     * @link https://book.cakephp.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeRender(IEvent $event) {
    }

    /**
     * The beforeRedirect method is invoked when the controller"s redirect method is called but before any
     * further action.
     *
     * If the event is stopped the controller will not continue on to redirect the request.
     * The $url and $status variables have same meaning as for the controller"s method.
     * You can set the event result to response instance or modify the redirect location
     * using controller"s response instance.
     *
     * @param uim.cake.events.IEvent $event An Event instance
     * @param array|string $url A string or array-based URL pointing to another location within the app,
     *     or an absolute URL
     * @param uim.cake.http.Response $response The response object.
     * @return uim.cake.http.Response|null|void
     * @link https://book.cakephp.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeRedirect(IEvent $event, $url, Response $response) {
    }

    /**
     * Called after the controller action is run and rendered.
     *
     * @param uim.cake.events.IEvent $event An Event instance
     * @return uim.cake.http.Response|null|void
     * @link https://book.cakephp.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function afterFilter(IEvent $event) {
    }
}
