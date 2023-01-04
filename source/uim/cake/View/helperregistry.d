module uim.cake.View;

import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
import uim.cake.events.IEventDispatcher;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.View\exceptions.MissingHelperException;

/**
 * HelperRegistry is used as a registry for loaded helpers and handles loading
 * and constructing helper class objects.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.View\Helper>
 */
class HelperRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * View object to use when making helpers.
     *
     * @var uim.cake.View\View
     */
    protected $_View;

    /**
     * Constructor
     *
     * @param uim.cake.View\View $view View object.
     */
    this(View $view) {
        _View = $view;
        this.setEventManager($view.getEventManager());
    }

    /**
     * Tries to lazy load a helper based on its name, if it cannot be found
     * in the application folder, then it tries looking under the current plugin
     * if any
     *
     * @param string $helper The helper name to be loaded
     * @return bool whether the helper could be loaded or not
     * @throws uim.cake.View\exceptions.MissingHelperException When a helper could not be found.
     *    App helpers are searched, and then plugin helpers.
     */
    bool __isSet(string $helper) {
        if (isset(_loaded[$helper])) {
            return true;
        }

        try {
            this.load($helper);
        } catch (MissingHelperException $exception) {
            $plugin = _View.getPlugin();
            if (!empty($plugin)) {
                this.load($plugin ~ "." ~ $helper);

                return true;
            }
        }

        if (!empty($exception)) {
            throw $exception;
        }

        return true;
    }

    /**
     * Provide read access to the loaded objects
     *
     * @param string aName Name of property to read
     * @return uim.cake.View\Helper|null
     */
    function __get(string aName) {
        if (isset(_loaded[$name])) {
            return _loaded[$name];
        }
        if (isset(this.{$name})) {
            return _loaded[$name];
        }

        return null;
    }

    /**
     * Resolve a helper classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "View/Helper", "Helper");
    }

    /**
     * Throws an exception when a helper is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the helper is missing in.
     * @return void
     * @throws uim.cake.View\exceptions.MissingHelperException
     */
    protected void _throwMissingClassError(string $class, ?string $plugin)
    {
        throw new MissingHelperException([
            "class": $class ~ "Helper",
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the helper instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * Enabled helpers will be registered with the event manager.
     *
     * @param string $class The class to create.
     * @param string $alias The alias of the loaded helper.
     * @param array<string, mixed> $config An array of settings to use for the helper.
     * @return uim.cake.View\Helper The constructed helper class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected function _create($class, string $alias, array $config): Helper
    {
        /** @var uim.cake.View\Helper $instance */
        $instance = new $class(_View, $config);

        $enable = $config["enabled"] ?? true;
        if ($enable) {
            this.getEventManager().on($instance);
        }

        return $instance;
    }
}
