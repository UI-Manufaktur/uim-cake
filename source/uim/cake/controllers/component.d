module uim.cake.controllers;

import uim.cake.core.InstanceConfigTrait;
import uim.cakeents\IEventListener;
import uim.cakegs\LogTrait;

/**
 * Base class for an individual Component. Components provide reusable bits of
 * controller logic that can be composed into a controller. Components also
 * provide request life-cycle callbacks for injecting logic at specific points.
 *
 * ### Initialize hook
 *
 * Like Controller and Table, this class has an initialize() hook that you can use
 * to add custom "constructor" logic. It is important to remember that each request
 * (and sub-request) will only make one instance of any given component.
 *
 * ### Life cycle callbacks
 *
 * Components can provide several callbacks that are fired at various stages of the request
 * cycle. The available callbacks are:
 *
 * - `beforeFilter(IEvent myEvent)`
 *   Called before Controller::beforeFilter() method by default.
 * - `startup(IEvent myEvent)`
 *   Called after Controller::beforeFilter() method, and before the
 *   controller action is called.
 * - `beforeRender(IEvent myEvent)`
 *   Called before Controller::beforeRender(), and before the view class is loaded.
 * - `afterFilter(IEvent myEvent)`
 *   Called after the action is complete and the view has been rendered but
 *   before Controller::afterFilter().
 * - `beforeRedirect(IEvent myEvent myUrl, Response $response)`
 *   Called before a redirect is done. Allows you to change the URL that will
 *   be redirected to by returning a Response instance with new URL set using
 *   Response::location(). Redirection can be prevented by stopping the event
 *   propagation.
 *
 * While the controller is not an explicit argument for the callback methods it
 * is the subject of each event and can be fetched using IEvent::getSubject().
 *
 * @link https://book.UIM.org/4/en/controllers/components.html
 * @see \Cake\Controller\Controller::$components
 */
class Component : IEventListener
{
    use InstanceConfigTrait;
    use LogTrait;

    /**
     * Component registry class used to lazy load components.
     *
     * @var \Cake\Controller\ComponentRegistry
     */
    protected $_registry;

    /**
     * Other Components this component uses.
     *
     * @var array
     */
    protected $components = [];

    /**
     * Default config
     *
     * These are merged with user-provided config when the component is used.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * A component lookup table used to lazy load component objects.
     *
     * @var array<string, array>
     */
    protected $_componentMap = [];

    /**
     * Constructor
     *
     * @param \Cake\Controller\ComponentRegistry $registry A component registry
     *  this component can use to lazy load its components.
     * @param array<string, mixed> myConfig Array of configuration settings.
     */
    this(ComponentRegistry $registry, array myConfig = []) {
        this._registry = $registry;

        this.setConfig(myConfig);

        if (this.components) {
            this._componentMap = $registry.normalizeArray(this.components);
        }
        this.initialize(myConfig);
    }

    /**
     * Get the controller this component is bound to.
     *
     * @return \Cake\Controller\Controller The bound controller.
     */
    auto getController(): Controller
    {
        return this._registry.getController();
    }

    /**
     * Constructor hook method.
     *
     * Implement this method to avoid having to overwrite
     * the constructor and call parent.
     *
     * @param array<string, mixed> myConfig The configuration settings provided to this component.
     */
    void initialize(array myConfig) {
    }

    /**
     * Magic method for lazy loading $components.
     *
     * @param string myName Name of component to get.
     * @return \Cake\Controller\Component|null A Component object or null.
     */
    auto __get(string myName) {
        if (isset(this._componentMap[myName]) && !isset(this.{myName})) {
            myConfig = (array)this._componentMap[myName]["config"] + ["enabled" => false];
            this.{myName} = this._registry.load(this._componentMap[myName]["class"], myConfig);
        }

        return this.{myName} ?? null;
    }

    /**
     * Get the Controller callbacks this Component is interested in.
     *
     * Uses Conventions to map controller events to standard component
     * callback method names. By defining one of the callback methods a
     * component is assumed to be interested in the related event.
     *
     * Override this method if you need to add non-conventional event listeners.
     * Or if you want components to listen to non-standard events.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        myEventMap = [
            "Controller.initialize" => "beforeFilter",
            "Controller.startup" => "startup",
            "Controller.beforeRender" => "beforeRender",
            "Controller.beforeRedirect" => "beforeRedirect",
            "Controller.shutdown" => "afterFilter",
        ];
        myEvents = [];
        foreach (myEventMap as myEvent => $method) {
            if (method_exists(this, $method)) {
                myEvents[myEvent] = $method;
            }
        }

        if (!isset(myEvents["Controller.shutdown"]) && method_exists(this, "shutdown")) {
            deprecationWarning(
                "`Controller.shutdown` event callback is now `afterFilter()` instead of `shutdown()`.",
                0
            );
            myEvents[myEvent] = "shutdown";
        }

        return myEvents;
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
            "components" => this.components,
            "implementedEvents" => this.implementedEvents(),
            "_config" => this.getConfig(),
        ];
    }
}
