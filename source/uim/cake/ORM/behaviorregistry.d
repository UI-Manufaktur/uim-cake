module uim.cake.ORM;

use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
import uim.cake.events.IEventDispatcher;
import uim.cake.events.EventDispatcherTrait;
import uim.cake.orm.exceptions.MissingBehaviorException;
use LogicException;

/**
 * BehaviorRegistry is used as a registry for loaded behaviors and handles loading
 * and constructing behavior objects.
 *
 * This class also provides method for checking and dispatching behavior methods.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.orm.Behavior>
 */
class BehaviorRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The table using this registry.
     *
     * @var uim.cake.orm.Table
     */
    protected $_table;

    /**
     * Method mappings.
     *
     * @var array<string, array>
     */
    protected $_methodMap = [];

    /**
     * Finder method mappings.
     *
     * @var array<string, array>
     */
    protected $_finderMap = [];

    /**
     * Constructor
     *
     * @param uim.cake.orm.Table|null $table The table this registry is attached to.
     */
    this(?Table $table = null) {
        if ($table != null) {
            this.setTable($table);
        }
    }

    /**
     * Attaches a table instance to this registry.
     *
     * @param uim.cake.orm.Table $table The table this registry is attached to.
     */
    void setTable(Table $table) {
        _table = $table;
        this.setEventManager($table.getEventManager());
    }

    /**
     * Resolve a behavior classname.
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct classname or null.
     * @psalm-return class-string|null
     */
    static function className(string $class): ?string
    {
        return App::className($class, "Model/Behavior", "Behavior")
            ?: App::className($class, "ORM/Behavior", "Behavior");
    }

    /**
     * Resolve a behavior classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return static::className($class);
    }

    /**
     * Throws an exception when a behavior is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the behavior is missing in.
     * @return void
     * @throws uim.cake.orm.exceptions.MissingBehaviorException
     */
    protected void _throwMissingClassError(string $class, ?string $plugin) {
        throw new MissingBehaviorException([
            "class": $class ~ "Behavior",
            "plugin": $plugin,
        ]);
    }

    /**
     * Create the behavior instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * Enabled behaviors will be registered with the event manager.
     *
     * @param string $class The classname that is missing.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config An array of config to use for the behavior.
     * @return uim.cake.orm.Behavior The constructed behavior class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected function _create($class, string $alias, array $config): Behavior
    {
        /** @var uim.cake.orm.Behavior $instance */
        $instance = new $class(_table, $config);
        $enable = $config["enabled"] ?? true;
        if ($enable) {
            this.getEventManager().on($instance);
        }
        $methods = _getMethods($instance, $class, $alias);
        _methodMap += $methods["methods"];
        _finderMap += $methods["finders"];

        return $instance;
    }

    /**
     * Get the behavior methods and ensure there are no duplicates.
     *
     * Use the implementedEvents() method to exclude callback methods.
     * Methods starting with `_` will be ignored, as will methods
     * declared on Cake\orm.Behavior
     *
     * @param uim.cake.orm.Behavior $instance The behavior to get methods from.
     * @param string $class The classname that is missing.
     * @param string $alias The alias of the object.
     * @return array A list of implemented finders and methods.
     * @throws \LogicException when duplicate methods are connected.
     */
    protected array _getMethods(Behavior $instance, string $class, string $alias) {
        $finders = array_change_key_case($instance.implementedFinders());
        $methods = array_change_key_case($instance.implementedMethods());

        foreach ($finders as $finder: $methodName) {
            if (isset(_finderMap[$finder]) && this.has(_finderMap[$finder][0])) {
                $duplicate = _finderMap[$finder];
                $error = sprintf(
                    "%s contains duplicate finder "%s" which is already provided by "%s"",
                    $class,
                    $finder,
                    $duplicate[0]
                );
                throw new LogicException($error);
            }
            $finders[$finder] = [$alias, $methodName];
        }

        foreach ($methods as $method: $methodName) {
            if (isset(_methodMap[$method]) && this.has(_methodMap[$method][0])) {
                $duplicate = _methodMap[$method];
                $error = sprintf(
                    "%s contains duplicate method "%s" which is already provided by "%s"",
                    $class,
                    $method,
                    $duplicate[0]
                );
                throw new LogicException($error);
            }
            $methods[$method] = [$alias, $methodName];
        }

        return compact("methods", "finders");
    }

    /**
     * Check if any loaded behavior : a method.
     *
     * Will return true if any behavior provides a non-finder method
     * with the chosen name.
     *
     * @param string $method The method to check for.
     */
    bool hasMethod(string $method) {
        $method = strtolower($method);

        return isset(_methodMap[$method]);
    }

    /**
     * Check if any loaded behavior : the named finder.
     *
     * Will return true if any behavior provides a method with
     * the chosen name.
     *
     * @param string $method The method to check for.
     */
    bool hasFinder(string $method) {
        $method = strtolower($method);

        return isset(_finderMap[$method]);
    }

    /**
     * Invoke a method on a behavior.
     *
     * @param string $method The method to invoke.
     * @param array $args The arguments you want to invoke the method with.
     * @return mixed The return value depends on the underlying behavior method.
     * @throws \BadMethodCallException When the method is unknown.
     */
    function call(string $method, array $args = []) {
        $method = strtolower($method);
        if (this.hasMethod($method) && this.has(_methodMap[$method][0])) {
            [$behavior, $callMethod] = _methodMap[$method];

            return _loaded[$behavior].{$callMethod}(...$args);
        }

        throw new BadMethodCallException(
            sprintf("Cannot call "%s" it does not belong to any attached behavior.", $method)
        );
    }

    /**
     * Invoke a finder on a behavior.
     *
     * @param string $type The finder type to invoke.
     * @param array $args The arguments you want to invoke the method with.
     * @return uim.cake.orm.Query The return value depends on the underlying behavior method.
     * @throws \BadMethodCallException When the method is unknown.
     */
    function callFinder(string $type, array $args = []): Query
    {
        $type = strtolower($type);

        if (this.hasFinder($type) && this.has(_finderMap[$type][0])) {
            [$behavior, $callMethod] = _finderMap[$type];
            $callable = [_loaded[$behavior], $callMethod];

            return $callable(...$args);
        }

        throw new BadMethodCallException(
            sprintf("Cannot call finder "%s" it does not belong to any attached behavior.", $type)
        );
    }
}
