
module uim.cake.controllers;

@safe:
import uim.cake;

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
 * UIM fires a number of life cycle callbacks during each request.
 * By implementing a method you can receive the related events. The available
 * callbacks are:
 *
 * - `beforeFilter(IEvent myEvent)`
 *   Called before each action. This is a good place to do general logic that
 *   applies to all actions.
 * - `beforeRender(IEvent myEvent)`
 *   Called before the view is rendered.
 * - `beforeRedirect(IEvent myEvent, myUrl, Response $response)`
 *    Called before a redirect is done.
 * - `afterFilter(IEvent myEvent)`
 *   Called after each action is complete and after the view is rendered.
 *
 * @property \Cake\Controller\Component\FlashComponent $Flash
 * @property \Cake\Controller\Component\FormProtectionComponent $FormProtection
 * @property \Cake\Controller\Component\PaginatorComponent $Paginator
 * @property \Cake\Controller\Component\RequestHandlerComponent myRequestHandler
 * @property \Cake\Controller\Component\SecurityComponent $Security
 * @property \Cake\Controller\Component\AuthComponent $Auth
 * @link https://book.UIM.org/4/en/controllers.html
 */
class Controller : IEventListener, IEventDispatcher
{
    use EventDispatcherTrait;
    use LocatorAwareTrait;
    use LogTrait;
    use ModelAwareTrait;
    use ViewVarsTrait;

    /**
     * The name of this controller. Controller names are plural, named after the model they manipulate.
     *
     * Set automatically using conventions in Controller::this().
     */
    protected string string myName;

    /**
     * An instance of a \Cake\Http\ServerRequest object that contains information about the current request.
     * This object contains all the information about a request and several methods for reading
     * additional information about the request.
     *
     * @var \Cake\Http\ServerRequest
     * @link https://book.UIM.org/4/en/controllers/request-response.html#request
     */
    protected myRequest;

    /**
     * An instance of a Response object that contains information about the impending response
     *
     * @var \Cake\Http\Response
     * @link https://book.UIM.org/4/en/controllers/request-response.html#response
     */
    protected $response;

    /**
     * Settings for pagination.
     *
     * Used to pre-configure pagination preferences for the various
     * tables your controller will be paginating.
     *
     * @var array
     * @see \Cake\Controller\Component\PaginatorComponent
     */
    public $paginate = [];

    /**
     * Set to true to automatically render the view
     * after action logic.
     *
     * @var bool
     */
    protected $autoRender = true;

    /**
     * Instance of ComponentRegistry used to create Components
     *
     * @var \Cake\Controller\ComponentRegistry|null
     */
    protected $_components;

    /**
     * Automatically set to the name of a plugin.
     *
     * @var string|null
     */
    protected myPlugin;

    /**
     * Middlewares list.
     *
     * @var array
     * @psalm-var array<int, array{middleware:\Psr\Http\Server\IMiddleware|\Closure|string, options:array{only?: array|string, except?: array|string}}>
     */
    protected $middlewares = [];

    /**
     * Constructor.
     *
     * Sets a number of properties based on conventions if they are empty. To override the
     * conventions UIM uses you can define properties in your class declaration.
     *
     * @param \Cake\Http\ServerRequest|null myRequest Request object for this controller. Can be null for testing,
     *   but expect that features that use the request parameters will not work.
     * @param \Cake\Http\Response|null $response Response object for this controller.
     * @param string|null myName Override the name useful in testing when using mocks.
     * @param \Cake\Event\IEventManager|null myEventManager The event manager. Defaults to a new instance.
     * @param \Cake\Controller\ComponentRegistry|null $components The component registry. Defaults to a new instance.
     */
    this(
        ?ServerRequest myRequest = null,
        ?Response $response = null,
        Nullable!string myName = null,
        ?IEventManager myEventManager = null,
        ?ComponentRegistry $components = null
    ) {
        if (myName !== null) {
            this.name = myName;
        } elseif (this.name == null && myRequest) {
            this.name = myRequest.getParam("controller");
        }

        if (this.name == null) {
            [, myName] = moduleSplit(static::class);
            this.name = substr(myName, 0, -10);
        }

        this.setRequest(myRequest ?: new ServerRequest());
        this.response = $response ?: new Response();

        if (myEventManager !== null) {
            this.setEventManager(myEventManager);
        }

        this.modelFactory("Table", [this.getTableLocator(), "get"]);

        if (this.defaultTable !== null) {
            this.modelClass = this.defaultTable;
        }

        if (this.modelClass == null) {
            myPlugin = this.request.getParam("plugin");
            myModelClass = (myPlugin ? myPlugin . "." : "") . this.name;
            this._setModelClass(myModelClass);

            this.defaultTable = myModelClass;
        }

        if ($components !== null) {
            this.components($components);
        }

        this.initialize();

        if (isset(this.components)) {
            triggerWarning(
                "Support for loading components using $components property is removed. " .
                "Use this.loadComponent() instead in initialize()."
            );
        }

        if (isset(this.helpers)) {
            triggerWarning(
                "Support for loading helpers using $helpers property is removed. " .
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
    override void initialize() {
    }

    /**
     * Get the component registry for this controller.
     *
     * If called with the first parameter, it will be set as the controller this._components property
     *
     * @param \Cake\Controller\ComponentRegistry|null $components Component registry.
     * @return \Cake\Controller\ComponentRegistry
     */
    ComponentRegistry components(?ComponentRegistry $components = null) {
        if ($components !== null) {
            $components.setController(this);

            return this._components = $components;
        }

        if (this._components == null) {
            this._components = new ComponentRegistry(this);
        }

        return this._components;
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
     * @param string myName The name of the component to load.
     * @param array<string, mixed> myConfig The config for the component.
     * @return \Cake\Controller\Component
     * @throws \Exception
     */
    Component loadComponent(string myName, array myConfig = []) {
        [, $prop] = pluginSplit(myName);

        return this.{$prop} = this.components().load(myName, myConfig);
    }

    /**
     * Magic accessor for model autoloading.
     *
     * @param string myName Property name
     * @return \Cake\Datasource\IRepository|null The model instance or null
     */
    auto __get(string myName) {
        if (!empty(this.modelClass)) {
            if (strpos(this.modelClass, "\\") == false) {
                [, myClass] = pluginSplit(this.modelClass, true);
            } else {
                myClass = App::shortName(this.modelClass, "Model/Table", "Table");
            }

            if (myClass == myName) {
                return this.loadModel();
            }
        }

        $trace = debug_backtrace();
        $parts = explode("\\", static::class);
        trigger_error(
            sprintf(
                "Undefined property: %s::$%s in %s on line %s",
                array_pop($parts),
                myName,
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
     * @param string propertyName Property name.
     * @param mixed myValue Value to set.
     */
    void __set(string propertyName, myValue) {
        if (propertyName == "components") {
            triggerWarning(
                "Support for loading components using $components property is removed. " .
                "Use this.loadComponent() instead in initialize()."
            );

            return;
        }

        if (propertyName == "helpers") {
            triggerWarning(
                "Support for loading helpers using $helpers property is removed. " .
                "Use this.viewBuilder().setHelpers() instead."
            );

            return;
        }

        this.{propertyName} = myValue;
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
     * @param string myName Controller name.
     * @return this

     */
    auto setName(string myName) {
        this.name = myName;

        return this;
    }

    /**
     * Returns the plugin name.
     *
     * @return string|null

     */
    string getPlugin() {
        return this.plugin;
    }

    /**
     * Sets the plugin name.
     *
     * @param string|null myName Plugin name.
     * @return this

     */
    auto setPlugin(Nullable!string myName) {
        this.plugin = myName;

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
     * @return \Cake\Http\ServerRequest

     */
    ServerRequest getRequest() {
        return this.request;
    }

    /**
     * Sets the request objects and configures a number of controller properties
     * based on the contents of the request. Controller acts as a proxy for certain View variables
     * which must also be updated here. The properties that get set are:
     *
     * - this.request - To the myRequest parameter
     *
     * @param \Cake\Http\ServerRequest myRequest Request instance.
     * @return this
     */
    auto setRequest(ServerRequest myRequest) {
        this.request = myRequest;
        this.plugin = myRequest.getParam("plugin") ?: null;

        return this;
    }

    /**
     * Gets the response instance.
     *
     * @return \Cake\Http\Response

     */
    Response getResponse() {
        return this.response;
    }

    /**
     * Sets the response instance.
     *
     * @param \Cake\Http\Response $response Response instance.
     * @return this

     */
    auto setResponse(Response $response) {
        this.response = $response;

        return this;
    }

    /**
     * Get the closure for action to be invoked by ControllerFactory.
     *
     * @return \Closure
     * @throws \Cake\Controller\Exception\MissingActionException
     */
    Closure getAction() {
        myRequest = this.request;
        $action = myRequest.getParam("action");

        if (!this.isAction($action)) {
            throw new MissingActionException([
                "controller":this.name . "Controller",
                "action":myRequest.getParam("action"),
                "prefix":myRequest.getParam("prefix") ?: "",
                "plugin":myRequest.getParam("plugin"),
            ]);
        }

        return Closure::fromCallable([this, $action]);
    }

    /**
     * Dispatches the controller action.
     *
     * @param \Closure $action The action closure.
     * @param array $args The arguments to be passed when invoking action.
     * @throws \UnexpectedValueException If return value of action is not `null` or `IResponse` instance.
     */
    void invokeAction(Closure $action, array $args) {
        myResult = $action(...$args);
        if (myResult !== null && !myResult instanceof IResponse) {
            throw new UnexpectedValueException(sprintf(
                "Controller actions can only return IResponse instance or null. "
                . "Got %s instead.",
                getTypeName(myResult)
            ));
        }
        if (myResult == null && this.isAutoRenderEnabled()) {
            myResult = this.render();
        }
        if (myResult) {
            this.response = myResult;
        }
    }

    /**
     * Register middleware for the controller.
     *
     * @param \Psr\Http\Server\IMiddleware|\Closure|string $middleware Middleware.
     * @param array<string, mixed> myOptions Valid options:
     *  - `only`: (array|string) Only run the middleware for specified actions.
     *  - `except`: (array|string) Run the middleware for all actions except the specified ones.
     * @psalm-param array{only?: array|string, except?: array|string} myOptions
     */
    void middleware($middleware, array myOptions = []) {
        this.middlewares[] = [
            "middleware":$middleware,
            "options":myOptions,
        ];
    }

    /**
     * Get middleware to be applied for this controller.
     *
     * @return array
     */
    array getMiddleware() {
        $matching = [];
        $action = this.request.getParam("action");

        foreach (this.middlewares as $middleware) {
            myOptions = $middleware["options"];
            if (!empty(myOptions["only"])) {
                if (in_array($action, (array)myOptions["only"], true)) {
                    $matching[] = $middleware["middleware"];
                }

                continue;
            }

            if (
                !empty(myOptions["except"]) &&
                in_array($action, (array)myOptions["except"], true)
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
            "Controller.initialize":"beforeFilter",
            "Controller.beforeRender":"beforeRender",
            "Controller.beforeRedirect":"beforeRedirect",
            "Controller.shutdown":"afterFilter",
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
     * @return \Psr\Http\Message\IResponse|null
     */
    function startupProcess(): ?IResponse
    {
        myEvent = this.dispatchEvent("Controller.initialize");
        if (myEvent.getResult() instanceof IResponse) {
            return myEvent.getResult();
        }
        myEvent = this.dispatchEvent("Controller.startup");
        if (myEvent.getResult() instanceof IResponse) {
            return myEvent.getResult();
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
     * @return \Psr\Http\Message\IResponse|null
     */
    function shutdownProcess(): ?IResponse
    {
        myEvent = this.dispatchEvent("Controller.shutdown");
        if (myEvent.getResult() instanceof IResponse) {
            return myEvent.getResult();
        }

        return null;
    }

    /**
     * Redirects to given myUrl, after turning off this.autoRender.
     *
     * @param \Psr\Http\Message\UriInterface|array|string myUrl A string, array-based URL or UriInterface instance.
     * @param int $status HTTP status code. Defaults to `302`.
     * @return \Cake\Http\Response|null
     * @link https://book.UIM.org/4/en/controllers.html#Controller::redirect
     */
    function redirect(myUrl, int $status = 302): ?Response
    {
        this.autoRender = false;

        if ($status) {
            this.response = this.response.withStatus($status);
        }

        myEvent = this.dispatchEvent("Controller.beforeRedirect", [myUrl, this.response]);
        if (myEvent.getResult() instanceof Response) {
            return this.response = myEvent.getResult();
        }
        if (myEvent.isStopped()) {
            return null;
        }
        $response = this.response;

        if (!$response.getHeaderLine("Location")) {
            $response = $response.withLocation(Router::url(myUrl, true));
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
    auto setAction(string $action, ...$args) {
        deprecationWarning(
            "Controller::setAction() is deprecated. Either refactor your code to use `redirect()`, " .
            "or call the other action as a method."
        );
        this.setRequest(this.request.withParam("action", $action));

        return this.$action(...$args);
    }

    /**
     * Instantiates the correct view class, hands it its data, and uses it to render the view output.
     *
     * @param string|null myTemplate Template to use for rendering
     * @param string|null $layout Layout to use
     * @return \Cake\Http\Response A response object containing the rendered view.
     * @link https://book.UIM.org/4/en/controllers.html#rendering-a-view
     */
    Response render(Nullable!string myTemplate = null, Nullable!string $layout = null) {
      myBuilder = this.viewBuilder();
      if (!myBuilder.getTemplatePath()) {
          myBuilder.setTemplatePath(this._templatePath());
      }

      this.autoRender = false;

      if (myTemplate !== null) {
        myBuilder.setTemplate(myTemplate);
      }

      if ($layout !== null) {
        myBuilder.setLayout($layout);
      }

      myEvent = this.dispatchEvent("Controller.beforeRender");
      if (myEvent.getResult() instanceof Response) {
        return myEvent.getResult();
      }
      if (myEvent.isStopped()) {
        return this.response;
      }

      if (myBuilder.getTemplate() == null) {
        myBuilder.setTemplate(this.request.getParam("action"));
      }

      $view = this.createView();
      myContentss = $view.render();
      this.setResponse($view.getResponse().withStringBody(myContentss));

      return this.response;
    }

    // Get the templatePath based on controller name and request prefix.
    protected string _templatePath() {
        myTemplatePath = this.name;
        if (this.request.getParam("prefix")) {
            $prefixes = array_map(
                "Cake\Utility\Inflector::camelize",
                explode("/", this.request.getParam("prefix"))
            );
            myTemplatePath = implode(DIRECTORY_SEPARATOR, $prefixes) . DIRECTORY_SEPARATOR . myTemplatePath;
        }

        return myTemplatePath;
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
            myUrl = Router::url($default, !$local);
            $base = this.request.getAttribute("base");
            if ($local && $base && strpos(myUrl, $base) == 0) {
                myUrl = substr(myUrl, strlen($base));
                if (myUrl[0] !== "/") {
                    myUrl = "/" . myUrl;
                }

                return myUrl;
            }

            return myUrl;
        }

        return $referer;
    }

    /**
     * Handles pagination of records in Table objects.
     *
     * Will load the referenced Table object, and have the PaginatorComponent
     * paginate the query using the request date and settings defined in `this.paginate`.
     *
     * This method will also make the PaginatorHelper available in the view.
     *
     * @param \Cake\ORM\Table|\Cake\ORM\Query|string|null $object Table to paginate
     * (e.g: Table instance, "TableName" or a Query object)
     * @param array<string, mixed> $settings The settings/configuration used for pagination.
     * @return \Cake\ORM\ResultSet|\Cake\Datasource\IResultSet Query results
     * @link https://book.UIM.org/4/en/controllers.html#paginating-a-model
     * @throws \RuntimeException When no compatible table object can be found.
     */
    function paginate($object = null, array $settings = []) {
        if (is_object($object)) {
            myTable = $object;
        }

        if (is_string($object) || $object == null) {
            $try = [$object, this.modelClass];
            foreach ($try as myTableName) {
                if (empty(myTableName)) {
                    continue;
                }
                myTable = this.loadModel(myTableName);
                break;
            }
        }

        this.loadComponent("Paginator");
        if (empty(myTable)) {
            throw new RuntimeException("Unable to locate an object compatible with paginate.");
        }
        $settings += this.paginate;

        return this.Paginator.paginate(myTable, $settings);
    }

    /**
     * Method to check that an action is accessible from a URL.
     *
     * Override this method to change which controller methods can be reached.
     * The default implementation disallows access to all methods defined on Cake\Controller\Controller,
     * and allows all public methods on all subclasses of this class.
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
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @return \Cake\Http\Response|null|void
     * @link https://book.UIM.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeFilter(IEvent myEvent) {
    }

    /**
     * Called after the controller action is run, but before the view is rendered. You can use this method
     * to perform logic or set view variables that are required on every request.
     *
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @return \Cake\Http\Response|null|void
     * @link https://book.UIM.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeRender(IEvent myEvent) {
    }

    /**
     * The beforeRedirect method is invoked when the controller"s redirect method is called but before any
     * further action.
     *
     * If the event is stopped the controller will not continue on to redirect the request.
     * The myUrl and $status variables have same meaning as for the controller"s method.
     * You can set the event result to response instance or modify the redirect location
     * using controller"s response instance.
     *
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @param array|string myUrl A string or array-based URL pointing to another location within the app,
     *     or an absolute URL
     * @param \Cake\Http\Response $response The response object.
     * @return \Cake\Http\Response|null|void
     * @link https://book.UIM.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function beforeRedirect(IEvent myEvent, myUrl, Response $response) {
    }

    /**
     * Called after the controller action is run and rendered.
     *
     * @param \Cake\Event\IEvent myEvent An Event instance
     * @return \Cake\Http\Response|null|void
     * @link https://book.UIM.org/4/en/controllers.html#request-life-cycle-callbacks
     */
    function afterFilter(IEvent myEvent) {
    }
}
