module uim.cake.Controller;

import uim.cake.core.InstanceConfigTrait;
import uim.cake.events.IEventListener;
import uim.cake.logs.LogTrait;

/**
 * Base class for an individual Component. Components provide reusable bits of
 * controller logic that can be composed into a controller. Components also
 * provide request life-cycle callbacks for injecting logic at specific points.
 *
 * ### Initialize hook
 *
 * Like Controller and Table, this class has an initialize() hook that you can use
 * to add custom 'constructor' logic. It is important to remember that each request
 * (and sub-request) will only make one instance of any given component.
 *
 * ### Life cycle callbacks
 *
 * Components can provide several callbacks that are fired at various stages of the request
 * cycle. The available callbacks are:
 *
 * - `beforeFilter(IEvent $event)`
 *   Called before Controller::beforeFilter() method by default.
 * - `startup(IEvent $event)`
 *   Called after Controller::beforeFilter() method, and before the
 *   controller action is called.
 * - `beforeRender(IEvent $event)`
 *   Called before Controller::beforeRender(), and before the view class is loaded.
 * - `afterFilter(IEvent $event)`
 *   Called after the action is complete and the view has been rendered but
 *   before Controller::afterFilter().
 * - `beforeRedirect(IEvent $event $url, Response $response)`
 *   Called before a redirect is done. Allows you to change the URL that will
 *   be redirected to by returning a Response instance with new URL set using
 *   Response::location(). Redirection can be prevented by stopping the event
 *   propagation.
 *
 * While the controller is not an explicit argument for the callback methods it
 * is the subject of each event and can be fetched using IEvent::getSubject().
 *
 * @link https://book.cakephp.org/4/en/controllers/components.html
 * @see uim.cake.controllers.Controller::$components
 */
class Component : IEventListener {
    use InstanceConfigTrait;
    use LogTrait;

    // Component registry class used to lazy load components.
    protected ComponentRegistry _registry;

    /**
     * Other Components this component uses.
     *
     * @var array
     */
    protected $components = null;

    /**
     * Default config
     *
     * These are merged with user-provided config when the component is used.
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = null;

    /**
     * A component lookup table used to lazy load component objects.
     *
     * @var array<string, array>
     */
    protected _componentMap = null;

    /**
     * Constructor
     *
     * @param uim.cake.controllers.ComponentRegistry $registry A component registry
     *  this component can use to lazy load its components.
     * @param array<string, mixed> aConfig Array of configuration settings.
     */
    this(ComponentRegistry $registry, Json aConfig = null) {
        _registry = $registry;

        this.setConfig(aConfig);

        if (this.components) {
            _componentMap = $registry.normalizeArray(this.components);
        }
        this.initialize(aConfig);
    }

    /**
     * Get the controller this component is bound to.
     *
     * @return uim.cake.controllers.Controller The bound controller.
     */
    function getController(): Controller
    {
        return _registry.getController();
    }

    /**
     * Constructor hook method.
     *
     * Implement this method to avoid having to overwrite the constructor and call parent.
     *
     * @param array<string, mixed> aConfig The configuration settings provided to this component.
     */
    void initialize(Json aConfig) {
    }

    /**
     * Magic method for lazy loading $components.
     *
     * @param string aName Name of component to get.
     * @return uim.cake.controllers.Component|null A Component object or null.
     */
    function __get(string aName) {
        if (isset(_componentMap[$name]) && !isset(this.{$name})) {
            aConfig = (array)_componentMap[$name]['config'] + ['enabled': false];
            this.{$name} = _registry.load(_componentMap[$name]['class'], aConfig);
        }

        return this.{$name} ?? null;
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
    array implementedEvents() {
        $eventMap = [
            'Controller.initialize': 'beforeFilter',
            'Controller.startup': 'startup',
            'Controller.beforeRender': 'beforeRender',
            'Controller.beforeRedirect': 'beforeRedirect',
            'Controller.shutdown': 'afterFilter',
        ];
        $events = null;
        foreach ($eventMap as $event: $method) {
            if (method_exists(this, $method)) {
                $events[$event] = $method;
            }
        }

        if (!isset($events['Controller.shutdown']) && method_exists(this, 'shutdown')) {
            deprecationWarning(
                '`Controller.shutdown` event callback is now `afterFilter()` instead of `shutdown()`.',
                0
            );
            $events[$event] = 'shutdown';
        }

        return $events;
    }

    /**
     * Returns an array that can be used to describe the internal state of this
     * object.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() array
    {
        return [
            'components': this.components,
            'implementedEvents': this.implementedEvents(),
            '_config': this.getConfig(),
        ];
    }
}
