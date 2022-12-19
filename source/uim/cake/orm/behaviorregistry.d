module uim.cake.orm;

@safe:
import uim.cake;

/**
 * BehaviorRegistry is used as a registry for loaded behaviors and handles loading
 * and constructing behavior objects.
 *
 * This class also provides method for checking and dispatching behavior methods.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\ORM\Behavior>
 */
class BehaviorRegistry : ObjectRegistry : IEventDispatcher
{
    use EventDispatcherTrait;

    /**
     * The table using this registry.
     *
     * @var \Cake\ORM\Table
     */
    protected $_table;

    /**
     * Method mappings.
     *
     * @var array
     */
    protected $_methodMap = [];

    /**
     * Finder method mappings.
     *
     * @var array
     */
    protected $_finderMap = [];

    /**
     * Constructor
     *
     * @param \Cake\ORM\Table|null myTable The table this registry is attached to.
     */
    this(?Table myTable = null) {
        if (myTable !== null) {
            this.setTable(myTable);
        }
    }

    /**
     * Attaches a table instance to this registry.
     *
     * @param \Cake\ORM\Table myTable The table this registry is attached to.
     * @return void
     */
    void setTable(Table myTable) {
        _table = myTable;
        this.setEventManager(myTable.getEventManager());
    }

    /**
     * Resolve a behavior classname.
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct classname or null.
     * @psalm-return class-string|null
     */
    static Nullable!string className(string myClass) {
        return App::className(myClass, "Model/Behavior", "Behavior")
            ?: App::className(myClass, "ORM/Behavior", "Behavior");
    }

    /**
     * Resolve a behavior classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected Nullable!string _resolveClassName(string myClass) {
        return static::className(myClass);
    }

    /**
     * Throws an exception when a behavior is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * and Cake\Core\ObjectRegistry::unload()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the behavior is missing in.
     * @throws \Cake\ORM\Exception\MissingBehaviorException
     */
    protected void _throwMissingClassError(string myClass, Nullable!string myPlugin) {
        throw new MissingBehaviorException([
            "class":myClass . "Behavior",
            "plugin":myPlugin,
        ]);
    }

    /**
     * Create the behavior instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     * Enabled behaviors will be registered with the event manager.
     *
     * @param string myClass The classname that is missing.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of config to use for the behavior.
     * @return \Cake\ORM\Behavior The constructed behavior class.
     * @psalm-suppress MoreSpecificImplementedParamType
     */
    protected Behavior _create(myClass, string myAlias, array myConfig) {
        /** @var \Cake\ORM\Behavior $instance */
        $instance = new myClass(_table, myConfig);
        myEnable = myConfig["enabled"] ?? true;
        if (myEnable) {
            this.getEventManager().on($instance);
        }
        $methods = _getMethods($instance, myClass, myAlias);
        _methodMap += $methods["methods"];
        _finderMap += $methods["finders"];

        return $instance;
    }

    /**
     * Get the behavior methods and ensure there are no duplicates.
     *
     * Use the implementedEvents() method to exclude callback methods.
     * Methods starting with `_` will be ignored, as will methods
     * declared on Cake\ORM\Behavior
     *
     * @param \Cake\ORM\Behavior $instance The behavior to get methods from.
     * @param string myClass The classname that is missing.
     * @param string myAlias The alias of the object.
     * @return array A list of implemented finders and methods.
     * @throws \LogicException when duplicate methods are connected.
     */
    protected array _getMethods(Behavior $instance, string myClass, string myAlias) {
        myFinders = array_change_key_case($instance.implementedFinders());
        $methods = array_change_key_case($instance.implementedMethods());

        foreach (myFinders as myFinder: $methodName) {
            if (isset(_finderMap[myFinder]) && this.has(_finderMap[myFinder][0])) {
                $duplicate = _finderMap[myFinder];
                myError = sprintf(
                    "%s contains duplicate finder "%s" which is already provided by "%s"",
                    myClass,
                    myFinder,
                    $duplicate[0]
                );
                throw new LogicException(myError);
            }
            myFinders[myFinder] = [myAlias, $methodName];
        }

        foreach ($methods as $method: $methodName) {
            if (isset(_methodMap[$method]) && this.has(_methodMap[$method][0])) {
                $duplicate = _methodMap[$method];
                myError = sprintf(
                    "%s contains duplicate method "%s" which is already provided by "%s"",
                    myClass,
                    $method,
                    $duplicate[0]
                );
                throw new LogicException(myError);
            }
            $methods[$method] = [myAlias, $methodName];
        }

        return compact("methods", "finders");
    }

    /**
     * Check if any loaded behavior : a method.
     *
     * Will return true if any behavior provides a public non-finder method
     * with the chosen name.
     *
     * @param string $method The method to check for.
     * @return bool
     */
    bool hasMethod(string $method) {
        $method = strtolower($method);

        return isset(_methodMap[$method]);
    }

    /**
     * Check if any loaded behavior : the named finder.
     *
     * Will return true if any behavior provides a public method with
     * the chosen name.
     *
     * @param string $method The method to check for.
     * @return bool
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
     * @param string myType The finder type to invoke.
     * @param array $args The arguments you want to invoke the method with.
     * @return \Cake\ORM\Query The return value depends on the underlying behavior method.
     * @throws \BadMethodCallException When the method is unknown.
     */
    function callFinder(string myType, array $args = []): Query
    {
        myType = strtolower(myType);

        if (this.hasFinder(myType) && this.has(_finderMap[myType][0])) {
            [$behavior, $callMethod] = _finderMap[myType];
            $callable = [_loaded[$behavior], $callMethod];

            return $callable(...$args);
        }

        throw new BadMethodCallException(
            sprintf("Cannot call finder "%s" it does not belong to any attached behavior.", myType)
        );
    }
}
