module uim.baklava.controller;

import uim.baklava.controller\Exception\MissingComponentException;
import uim.baklava.core.App;
import uim.baklava.core.Exception\CakeException;
import uim.baklava.core.ObjectRegistry;
import uim.baklava.events\IEventDispatcher;
import uim.baklava.events\EventDispatcherTrait;

/**
 * ComponentRegistry is a registry for loaded components
 *
 * Handles loading, constructing and binding events for component class objects.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\Controller\Component>
 */
class ComponentRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The controller that this collection was initialized with.
     *
     * @var \Cake\Controller\Controller|null
     */
    protected $_controller;

    /**
     * Constructor.
     *
     * @param \Cake\Controller\Controller|null $controller Controller instance.
     */
    this(?Controller $controller = null) {
        if ($controller) {
            this.setController($controller);
        }
    }

    /**
     * Get the controller associated with the collection.
     *
     * @return \Cake\Controller\Controller Controller instance or null if not set.
     */
    auto getController(): Controller
    {
        if (this._controller === null) {
            throw new CakeException('Controller not set for ComponentRegistry');
        }

        return this._controller;
    }

    /**
     * Set the controller associated with the collection.
     *
     * @param \Cake\Controller\Controller $controller Controller instance.
     * @return this
     */
    auto setController(Controller $controller) {
        this._controller = $controller;
        this.setEventManager($controller.getEventManager());

        return this;
    }

    /**
     * Resolve a component classname.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected string _resolveClassName(string myClass) {
        return App::className(myClass, 'Controller/Component', 'Component');
    }

    /**
     * Throws an exception when a component is missing.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}
     * and {@link \Cake\Core\ObjectRegistry::unload()}
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the component is missing in.
     * @return void
     * @throws \Cake\Controller\Exception\MissingComponentException
     */
    protected auto _throwMissingClassError(string myClass, ?string myPlugin): void
    {
        throw new MissingComponentException([
            'class' => myClass . 'Component',
            'plugin' => myPlugin,
        ]);
    }

    /**
     * Create the component instance.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}
     * Enabled components will be registered with the event manager.
     *
     * @param string myClass The classname to create.
     * @param string myAlias The alias of the component.
     * @param array<string, mixed> myConfig An array of config to use for the component.
     * @return \Cake\Controller\Component The constructed component class.
     * @psalm-suppress MoreSpecificImplementedParamType
     * @psalm-param class-string myClass
     */
    protected auto _create(myClass, string myAlias, array myConfig): Component
    {
        /** @var \Cake\Controller\Component $instance */
        $instance = new myClass(this, myConfig);
        myEnable = myConfig['enabled'] ?? true;
        if (myEnable) {
            this.getEventManager().on($instance);
        }

        return $instance;
    }
}
