module uim.cake.Console;

import uim.cake.consoles.exceptions.MissingHelperException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;

/**
 * Registry for Helpers. Provides features
 * for lazily loading helpers.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.consoles.Helper>
 */
class HelperRegistry : ObjectRegistry
{
    /**
     * Shell to use to set params to tasks.
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected $_io;

    /**
     * Sets The IO instance that should be passed to the shell helpers
     *
     * @param uim.cake.consoles.ConsoleIo $io An io instance.
     */
    void setIo(ConsoleIo $io) {
        _io = $io;
    }

    /**
     * Resolve a helper classname.
     *
     * Will prefer helpers defined in Command\Helper over those
     * defined in Shell\Helper.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}.
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string
     */
    protected Nullable!string _resolveClassName(string $class)
    {
        $name = App::className($class, "Command/Helper", "Helper");
        if ($name == null) {
            return App::className($class, "Shell/Helper", "Helper");
        }

        return $name;
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
     * @throws uim.cake.consoles.exceptions.MissingHelperException
     */
    protected void _throwMissingClassError(string $class, ?string $plugin) {
        throw new MissingHelperException([
            "class": $class,
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the helper instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname to create.
     * @param string $alias The alias of the helper.
     * @param array<string, mixed> $config An array of settings to use for the helper.
     * @return uim.cake.consoles.Helper The constructed helper class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected function _create($class, string $alias, Json aConfig): Helper
    {
        /** @var uim.cake.consoles.Helper */
        return new $class(_io, $config);
    }
}
