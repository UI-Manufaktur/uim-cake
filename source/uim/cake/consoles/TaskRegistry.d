module uim.cake.Console;

import uim.cake.consoles.exceptions.MissingTaskException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;

/**
 * Registry for Tasks. Provides features
 * for lazily loading tasks.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.consoles.Shell>
 */
class TaskRegistry : ObjectRegistry
{
    /**
     * Shell to use to set params to tasks.
     *
     * @var uim.cake.consoles.Shell
     */
    protected _Shell;

    /**
     * Constructor
     *
     * @param uim.cake.consoles.Shell $shell Shell instance
     */
    this(Shell $shell) {
        _Shell = $shell;
    }

    /**
     * Resolve a task classname.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}.
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected Nullable!string _resolveClassName(string $class)
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
     * @throws uim.cake.consoles.exceptions.MissingTaskException
     */
    protected void _throwMissingClassError(string $class, ?string $plugin) {
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
     * @param array<string, mixed> aConfig An array of settings to use for the task.
     * @return uim.cake.consoles.Shell The constructed task class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected function _create($class, string $alias, Json aConfig): Shell
    {
        /** @var uim.cake.consoles.Shell */
        return new $class(_Shell.getIo());
    }
}
