module uim.cake.views;

@safe:
import uim.cake;

/**
 * HelperRegistry is used as a registry for loaded helpers and handles loading
 * and constructing helper class objects.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\View\Helper>
 */
class HelperRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * View object to use when making helpers.
     *
     * @var \Cake\View\View
     */
    protected $_View;

    /**
     * Constructor
     *
     * @param \Cake\View\View $view View object.
     */
    this(View $view) {
        this._View = $view;
        this.setEventManager($view.getEventManager());
    }

    /**
     * Tries to lazy load a helper based on its name, if it cannot be found
     * in the application folder, then it tries looking under the current plugin
     * if any
     *
     * @param string $helper The helper name to be loaded
     * @return bool whether the helper could be loaded or not
     * @throws \Cake\View\Exception\MissingHelperException When a helper could not be found.
     *    App helpers are searched, and then plugin helpers.
     */
    bool __isset(string $helper) {
        if (isset(this._loaded[$helper])) {
            return true;
        }

        try {
            this.load($helper);
        } catch (MissingHelperException myException) {
            myPlugin = this._View.getPlugin();
            if (!empty(myPlugin)) {
                this.load(myPlugin . "." . $helper);

                return true;
            }
        }

        if (!empty(myException)) {
            throw myException;
        }

        return true;
    }

    /**
     * Provide public read access to the loaded objects
     *
     * @param string myName Name of property to read
     * @return \Cake\View\Helper|null
     */
    auto __get(string myName) {
        if (isset(this._loaded[myName])) {
            return this._loaded[myName];
        }
        if (isset(this.{myName})) {
            return this._loaded[myName];
        }

        return null;
    }

    /**
     * Resolve a helper classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected auto _resolveClassName(string myClass): Nullable!string
    {
        return App::className(myClass, "View/Helper", "Helper");
    }

    /**
     * Throws an exception when a helper is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the helper is missing in.
     * @throws \Cake\View\Exception\MissingHelperException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingHelperException([
            "class" => myClass . "Helper",
            "plugin" => myPlugin,
        ]);
    }

    /**
     * Create the helper instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * Enabled helpers will be registered with the event manager.
     *
     * @param string myClass The class to create.
     * @param string myAlias The alias of the loaded helper.
     * @param array<string, mixed> myConfig An array of settings to use for the helper.
     * @return \Cake\View\Helper The constructed helper class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected auto _create(myClass, string myAlias, array myConfig): Helper
    {
        /** @var \Cake\View\Helper $instance */
        $instance = new myClass(this._View, myConfig);

        myEnable = myConfig["enabled"] ?? true;
        if (myEnable) {
            this.getEventManager().on($instance);
        }

        return $instance;
    }
}
