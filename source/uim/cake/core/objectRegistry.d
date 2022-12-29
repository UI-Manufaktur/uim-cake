module uim.cake.core;

use ArrayIterator;
import uim.cakeents\IEventDispatcher;
import uim.cakeents\IEventListener;
use Countable;
use IteratorAggregate;
use RuntimeException;
use Traversable;

/**
 * Acts as a registry/factory for objects.
 *
 * Provides registry & factory functionality for object types. Used
 * as a super class for various composition based re-use features in UIM.
 *
 * Each subclass needs to implement the various abstract methods to complete
 * the template method load().
 *
 * The ObjectRegistry is EventManager aware, but each extending class will need to use
 * uim.cake.Event\EventDispatcherTrait to attach and detach on set and bind
 *
 * @see uim.cake.controllers.ComponentRegistry
 * @see uim.cake.View\HelperRegistry
 * @see uim.cake.consoles.TaskRegistry
 * @template TObject
 */
abstract class ObjectRegistry : Countable, IteratorAggregate
{
    /**
     * Map of loaded objects.
     *
     * @var array<object>
     * @psalm-var array<array-key, TObject>
     */
    protected _loaded = [];

    /**
     * Loads/constructs an object instance.
     *
     * Will return the instance in the registry if it already exists.
     * If a subclass provides event support, you can use `myConfig["enabled"] = false`
     * to exclude constructed objects from being registered for events.
     *
     * Using {@link uim.cake.Controller\Component::$components} as an example. You can alias
     * an object by setting the "className" key, i.e.,
     *
     * ```
     * protected components = [
     *   "Email":[
     *     "className":"App\Controller\Component\AliasedEmailComponent"
     *   ];
     * ];
     * ```
     *
     * All calls to the `Email` component would use `AliasedEmail` instead.
     *
     * @param string myName The name/class of the object to load.
     * @param array<string, mixed> myConfig Additional settings to use when loading the object.
     * @return mixed
     * @psalm-return TObject
     * @throws \Exception If the class cannot be found.
     */
    function load(string myName, array myConfig = []) {
        if (isset(myConfig["className"])) {
            $objName = myName;
            myName = myConfig["className"];
        } else {
            [, $objName] = pluginSplit(myName);
        }

        $loaded = isset(_loaded[$objName]);
        if ($loaded && !empty(myConfig)) {
            _checkDuplicate($objName, myConfig);
        }
        if ($loaded) {
            return _loaded[$objName];
        }

        myClassName = myName;
        if (is_string(myName)) {
            myClassName = _resolveClassName(myName);
            if (myClassName is null) {
                [myPlugin, myName] = pluginSplit(myName);
                _throwMissingClassError(myName, myPlugin);
            }
        }

        /**
         * @psalm-var TObject $instance
         * @psalm-suppress PossiblyNullArgument
         **/
        $instance = _create(myClassName, $objName, myConfig);
        _loaded[$objName] = $instance;

        return $instance;
    }

    /**
     * Check for duplicate object loading.
     *
     * If a duplicate is being loaded and has different configuration, that is
     * bad and an exception will be raised.
     *
     * An exception is raised, as replacing the object will not update any
     * references other objects may have. Additionally, simply updating the runtime
     * configuration is not a good option as we may be missing important constructor
     * logic dependent on the configuration.
     *
     * @param string myName The name of the alias in the registry.
     * @param array<string, mixed> myConfig The config data for the new instance.
     * @throws \RuntimeException When a duplicate is found.
     */
    protected void _checkDuplicate(string myName, array myConfig) {
        $existing = _loaded[myName];
        $msg = sprintf("The "%s" alias has already been loaded.", myName);
        $hasConfig = method_exists($existing, "getConfig");
        if (!$hasConfig) {
            throw new RuntimeException($msg);
        }
        if (empty(myConfig)) {
            return;
        }
        $existingConfig = $existing.getConfig();
        unset(myConfig["enabled"], $existingConfig["enabled"]);

        $failure = null;
        foreach (myConfig as myKey: myValue) {
            if (!array_key_exists(myKey, $existingConfig)) {
                $failure = " The `{myKey}` was not defined in the previous configuration data.";
                break;
            }
            if (isset($existingConfig[myKey]) && $existingConfig[myKey] != myValue) {
                $failure = sprintf(
                    " The `%s` key has a value of `%s` but previously had a value of `%s`",
                    myKey,
                    json_encode(myValue),
                    json_encode($existingConfig[myKey])
                );
                break;
            }
        }
        if ($failure) {
            throw new RuntimeException($msg . $failure);
        }
    }

    /**
     * Should resolve the classname for a given object type.
     *
     * @param string myClass The class to resolve.
     * @return string|null The resolved name or null for failure.
     * @psalm-return class-string|null
     */
    abstract protected string _resolveClassName(string myClass);

    /**
     * Throw an exception when the requested object name is missing.
     *
     * @param string myClass The class that is missing.
     * @param string|null myPlugin The plugin myClass is missing from.
     * @throws \Exception
     */
    abstract protected void _throwMissingClassError(string myClass, Nullable!string myPlugin);

    /**
     * Create an instance of a given classname.
     *
     * This method should construct and do any other initialization logic
     * required.
     *
     * @param object|string myClass The class to build.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig The Configuration settings for construction
     * @return object
     * @psalm-param TObject|string myClass
     * @psalm-return TObject
     */
    abstract protected auto _create(myClass, string myAlias, array myConfig);

    /**
     * Get the list of loaded objects.
     *
     * @return List of object names.
     */
    string[] loaded() {
        return array_keys(_loaded);
    }

    /**
     * Check whether a given object is loaded.
     *
     * @param string myName The object name to check for.
     * @return bool True is object is loaded else false.
     */
    bool has(string myName) {
        return isset(_loaded[myName]);
    }

    /**
     * Get loaded object instance.
     *
     * @param string myName Name of object.
     * @return object Object instance.
     * @throws \RuntimeException If not loaded or found.
     * @psalm-return TObject
     */
    auto get(string myName) {
        if (!isset(_loaded[myName])) {
            throw new RuntimeException(sprintf("Unknown object "%s"", myName));
        }

        return _loaded[myName];
    }

    /**
     * Provide read access to the loaded objects
     *
     * @param string myName Name of property to read
     * @return object|null
     * @psalm-return TObject|null
     */
    auto __get(string myName) {
        return _loaded[myName] ?? null;
    }

    /**
     * Provide isset access to _loaded
     *
     * @param string myName Name of object being checked.
     */
    bool __isset(string myName) {
        return this.has(myName);
    }

    /**
     * Sets an object.
     *
     * @param string myName Name of a property to set.
     * @param object $object Object to set.
     * @psalm-param TObject $object
     */
    void __set(string myName, $object) {
        this.set(myName, $object);
    }

    /**
     * Unsets an object.
     *
     * @param string myName Name of a property to unset.
     */
    void __unset(string myName) {
        this.unload(myName);
    }

    /**
     * Normalizes an object array, creates an array that makes lazy loading
     * easier
     *
     * @param array $objects Array of child objects to normalize.
     * @return array<string, array> Array of normalized objects.
     */
    array normalizeArray(array $objects) {
        $normal = [];
        foreach ($i, $objectName; $objects) {
            myConfig = [];
            if (!is_int($i)) {
                myConfig = (array)$objectName;
                $objectName = $i;
            }
            [, myName] = pluginSplit($objectName);
            if (isset(myConfig["class"])) {
                $normal[myName] = myConfig + ["config":[]];
            } else {
                $normal[myName] = ["class":$objectName, "config":myConfig];
            }
        }

        return $normal;
    }

    /**
     * Clear loaded instances in the registry.
     *
     * If the registry subclass has an event manager, the objects will be detached from events as well.
     *
     * @return this
     */
    function reset() {
        foreach (array_keys(_loaded) as myName) {
            this.unload((string)myName);
        }

        return this;
    }

    /**
     * Set an object directly into the registry by name.
     *
     * If this collection : events, the passed object will
     * be attached into the event manager
     *
     * @param string myName The name of the object to set in the registry.
     * @param object $object instance to store in the registry
     * @return this
     * @psalm-param TObject $object
     * @psalm-suppress MoreSpecificReturnType
     */
    auto set(string myName, object $object) {
        [, $objName] = pluginSplit(myName);

        // Just call unload if the object was loaded before
        if (array_key_exists(myName, _loaded)) {
            this.unload(myName);
        }
        if (this instanceof IEventDispatcher && $object instanceof IEventListener) {
            this.getEventManager().on($object);
        }
        _loaded[$objName] = $object;

        /** @psalm-suppress LessSpecificReturnStatement */
        return this;
    }

    /**
     * Remove an object from the registry.
     *
     * If this registry has an event manager, the object will be detached from any events as well.
     *
     * @param string myName The name of the object to remove from the registry.
     * @return this
     * @psalm-suppress MoreSpecificReturnType
     */
    function unload(string myName) {
        if (empty(_loaded[myName])) {
            [myPlugin, myName] = pluginSplit(myName);
            _throwMissingClassError(myName, myPlugin);
        }

        $object = _loaded[myName];
        if (this instanceof IEventDispatcher && $object instanceof IEventListener) {
            this.getEventManager().off($object);
        }
        unset(_loaded[myName]);

        /** @psalm-suppress LessSpecificReturnStatement */
        return this;
    }

    /**
     * Returns an array iterator.
     *
     * @return \Traversable
     * @psalm-return \Traversable<string, TObject>
     */
    Traversable getIterator() {
        return new ArrayIterator(_loaded);
    }

    /**
     * Returns the number of loaded objects.
     */
    int count() {
        return count(_loaded);
    }

    /**
     * Debug friendly object properties.
     *
     * @return array<string, mixed>
     */
    array __debugInfo() {
        $properties = get_object_vars(this);
        if (isset($properties["_loaded"])) {
            $properties["_loaded"] = array_keys($properties["_loaded"]);
        }

        return $properties;
    }
}
