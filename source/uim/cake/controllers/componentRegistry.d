module uim.cake.controllers;

import uim.cake.controllers\exceptions.MissingComponentException;
import uim.cake.core.App;
import uim.cake.core.exceptions\CakeException;
import uim.cake.core.ObjectRegistry;
import uim.cakeents\IEventDispatcher;
import uim.cakeents\EventDispatcherTrait;

/**
 * ComponentRegistry is a registry for loaded components
 *
 * Handles loading, constructing and binding events for component class objects.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.Controller\Component>
 */
class ComponentRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The controller that this collection was initialized with.
     *
     * @var uim.cake.controllers.Controller|null
     */
    protected _controller;

    /**
     * Constructor.
     *
     * @param uim.cake.controllers.Controller|null $controller Controller instance.
     */
    this(?Controller $controller = null) {
        if ($controller) {
            this.setController($controller);
        }
    }

    /**
     * Get the controller associated with the collection.
     *
     * @return uim.cake.controllers.Controller Controller instance or null if not set.
     */
    Controller getController() {
        if (_controller is null) {
            throw new CakeException("Controller not set for ComponentRegistry");
        }

        return _controller;
    }

    /**
     * Set the controller associated with the collection.
     *
     * @param uim.cake.controllers.Controller $controller Controller instance.
     * @return this
     */
    auto setController(Controller $controller) {
        _controller = $controller;
        this.setEventManager($controller.getEventManager());

        return this;
    }

    /**
     * Resolve a component classname.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected string _resolveClassName(string myClass) {
        return App::className(myClass, "Controller/Component", "Component");
    }

    /**
     * Throws an exception when a component is missing.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}
     * and {@link uim.cake.Core\ObjectRegistry::unload()}
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the component is missing in.
     * @throws uim.cake.controllers.exceptions.MissingComponentException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingComponentException([
            "class":myClass . "Component",
            "plugin":myPlugin,
        ]);
    }

    /**
     * Create the component instance.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}
     * Enabled components will be registered with the event manager.
     *
     * @param string myClass The classname to create.
     * @param string myAlias The alias of the component.
     * @param array<string, mixed> myConfig An array of config to use for the component.
     * @return uim.cake.controllers.Component The constructed component class.
     * @psalm-suppress MoreSpecificImplementedParamType
     * @psalm-param class-string myClass
     */
    protected Component _create(myClass, string myAlias, array myConfig) {
        /** @var uim.cake.controllers.Component $instance */
        $instance = new myClass(this, myConfig);
        myEnable = myConfig["enabled"] ?? true;
        if (myEnable) {
            this.getEventManager().on($instance);
        }

        return $instance;
    }
}
