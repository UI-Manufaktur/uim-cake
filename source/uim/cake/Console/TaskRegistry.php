


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

import uim.cake.consoles.exceptions.MissingTaskException;
import uim.cake.cores.App;
import uim.cake.cores.ObjectRegistry;

/**
 * Registry for Tasks. Provides features
 * for lazily loading tasks.
 *
 * @: \Cake\Core\ObjectRegistry<\Cake\Console\Shell>
 */
class TaskRegistry : ObjectRegistry
{
    /**
     * Shell to use to set params to tasks.
     *
     * @var uim.cake.Console\Shell
     */
    protected $_Shell;

    /**
     * Constructor
     *
     * @param uim.cake.Console\Shell $shell Shell instance
     */
    public this(Shell $shell) {
        _Shell = $shell;
    }

    /**
     * Resolve a task classname.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}.
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "Shell/Task", "Task");
    }

    /**
     * Throws an exception when a task is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the task is missing in.
     * @return void
     * @throws \Cake\Console\Exception\MissingTaskException
     */
    protected function _throwMissingClassError(string $class, ?string $plugin): void
    {
        throw new MissingTaskException([
            "class": $class,
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the task instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname to create.
     * @param string $alias The alias of the task.
     * @param array<string, mixed> $config An array of settings to use for the task.
     * @return \Cake\Console\Shell The constructed task class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected function _create($class, string $alias, array $config): Shell
    {
        /** @var uim.cake.Console\Shell */
        return new $class(_Shell.getIo());
    }
}
