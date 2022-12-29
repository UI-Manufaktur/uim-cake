


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Controller;

import uim.cake.controllers.exceptions.MissingComponentException;
import uim.cake.core.App;
import uim.cake.core.exceptions.CakeException;
import uim.cake.core.ObjectRegistry;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.events.EventDispatcherTrait;

/**
 * ComponentRegistry is a registry for loaded components
 *
 * Handles loading, constructing and binding events for component class objects.
 *
 * @: \Cake\Core\ObjectRegistry<\Cake\Controller\Component>
 */
class ComponentRegistry : ObjectRegistry : EventDispatcherInterface
{
    use EventDispatcherTrait;

    /**
     * The controller that this collection was initialized with.
     *
     * @var uim.cake.controllers.Controller|null
     */
    protected $_Controller;

    /**
     * Constructor.
     *
     * @param uim.cake.controllers.Controller|null $controller Controller instance.
     */
    public this(?Controller $controller = null) {
        if ($controller) {
            this.setController($controller);
        }
    }

    /**
     * Get the controller associated with the collection.
     *
     * @return uim.cake.controllers.Controller Controller instance or null if not set.
     */
    function getController(): Controller
    {
        if (_Controller == null) {
            throw new CakeException("Controller not set for ComponentRegistry");
        }

        return _Controller;
    }

    /**
     * Set the controller associated with the collection.
     *
     * @param uim.cake.controllers.Controller $controller Controller instance.
     * @return this
     */
    function setController(Controller $controller) {
        _Controller = $controller;
        this.setEventManager($controller.getEventManager());

        return this;
    }

    /**
     * Resolve a component classname.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}.
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "Controller/Component", "Component");
    }

    /**
     * Throws an exception when a component is missing.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}
     * and {@link \Cake\Core\ObjectRegistry::unload()}
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the component is missing in.
     * @return void
     * @throws uim.cake.controllers.Exception\MissingComponentException
     */
    protected function _throwMissingClassError(string $class, ?string $plugin): void
    {
        throw new MissingComponentException([
            "class": $class . "Component",
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the component instance.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}
     * Enabled components will be registered with the event manager.
     *
     * @param string $class The classname to create.
     * @param string $alias The alias of the component.
     * @param array<string, mixed> $config An array of config to use for the component.
     * @return uim.cake.controllers.Component The constructed component class.
     * @psalm-suppress MoreSpecificImplementedParamType
     * @psalm-param class-string $class
     */
    protected function _create($class, string $alias, array $config): Component
    {
        /** @var uim.cake.controllers.Component $instance */
        $instance = new $class(this, $config);
        $enable = $config["enabled"] ?? true;
        if ($enable) {
            this.getEventManager().on($instance);
        }

        return $instance;
    }
}
