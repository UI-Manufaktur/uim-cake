module uim.baklava.console;

import uim.baklava.console.Exception\MissingTaskException;
import uim.baklava.core.App;
import uim.baklava.core.ObjectRegistry;

/**
 * Registry for Tasks. Provides features
 * for lazily loading tasks.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\Console\Shell>
 */
class TaskRegistry : ObjectRegistry
{
    /**
     * Shell to use to set params to tasks.
     *
     * @var \Cake\Console\Shell
     */
    protected $_Shell;

    /**
     * Constructor
     *
     * @param \Cake\Console\Shell $shell Shell instance
     */
    this(Shell $shell) {
        this._Shell = $shell;
    }

    /**
     * Resolve a task classname.
     *
     * Part of the template method for {@link \Cake\Core\ObjectRegistry::load()}.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected auto _resolveClassName(string myClass): Nullable!string
    {
        return App::className(myClass, 'Shell/Task', 'Task');
    }

    /**
     * Throws an exception when a task is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the task is missing in.
     * @return void
     * @throws \Cake\Console\Exception\MissingTaskException
     */
    protected auto _throwMissingClassError(string myClass, Nullable!string myPlugin): void
    {
        throw new MissingTaskException([
            'class' => myClass,
            'plugin' => myPlugin,
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
     * @return \Cake\Console\Shell The constructed task class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected auto _create(myClass, string myAlias, array myConfig): Shell
    {
        /** @var \Cake\Console\Shell */
        return new myClass(this._Shell.getIo());
    }
}
