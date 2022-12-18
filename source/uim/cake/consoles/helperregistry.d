module uim.cake.console;

@safe:
import uim.cake;

/**
 * Registry for Helpers. Provides features
 * for lazily loading helpers.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\Console\Helper>
 */
class HelperRegistry : ObjectRegistry
{
    /**
     * Shell to use to set params to tasks.
     *
     * @var \Cake\Console\ConsoleIo
     */
    protected $_io;

    /**
     * Sets The IO instance that should be passed to the shell helpers
     *
     * @param \Cake\Console\ConsoleIo $io An io instance.
     */
    void setIo(ConsoleIo $io) {
        this._io = $io;
    }

    /**
     * Resolve a helper classname.
     *
     * Will prefer helpers defined in Command\Helper over those
     * defined in Shell\Helper.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string
     */
    protected auto _resolveClassName(string myClass): Nullable!string
    {
        myName = App::className(myClass, "Command/Helper", "Helper");
        if (myName == null) {
            return App::className(myClass, "Shell/Helper", "Helper");
        }

        return myName;
    }

    /**
     * Throws an exception when a helper is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the helper is missing in.
     * @throws \Cake\Console\Exception\MissingHelperException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingHelperException([
            "class":myClass,
            "plugin":myPlugin,
        ]);
    }

    /**
     * Create the helper instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname to create.
     * @param string myAlias The alias of the helper.
     * @param array<string, mixed> myConfig An array of settings to use for the helper.
     * @return \Cake\Console\Helper The constructed helper class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected auto _create(myClass, string myAlias, array myConfig): Helper
    {
        /** @var \Cake\Console\Helper */
        return new myClass(this._io, myConfig);
    }
}
