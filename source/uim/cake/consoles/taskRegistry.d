module uim.cake.console;

import uim.cake.console.exceptions\MissingTaskException;
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
     * @param uim.cake.consoles.Shell myShell Shell instance
     */
    this(Shell myShell) {
        _Shell = myShell;
    }

    /**
     * Resolve a task classname.
     *
     * Part of the template method for {@link uim.cake.Core\ObjectRegistry::load()}.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected Nullable!string _resolveClassName(string myClass) {
        return App::className(myClass, "Shell/Task", "Task");
    }

    /**
     * Throws an exception when a task is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the task is missing in.
     * @throws uim.cake.consoles.exceptions.MissingTaskException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingTaskException([
            "class":myClass,
            "plugin":myPlugin,
        ]);
    }

    /**
     * Create the task instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname to create.
     * @param string myAlias The alias of the task.
     * @param array<string, mixed> myConfig An array of settings to use for the task.
     * @return uim.cake.consoles.Shell The constructed task class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected Shell _create(myClass, string myAlias, array myConfig) {
        /** @var uim.cake.consoles.Shell */
        return new myClass(_Shell.getIo());
    }
}
