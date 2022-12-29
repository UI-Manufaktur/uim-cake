


 *


 * @since         3.0.0
  */
module uim.cake.Core;

use ArrayIterator;
import uim.cake.events.EventDispatcherInterface;
import uim.cake.events.IEventListener;
use Countable;
use IteratorAggregate;
use RuntimeException;
use Traversable;

/**
 * Acts as a registry/factory for objects.
 *
 * Provides registry & factory functionality for object types. Used
 * as a super class for various composition based re-use features in CakePHP.
 *
 * Each subclass needs to implement the various abstract methods to complete
 * the template method load().
 *
 * The ObjectRegistry is EventManager aware, but each extending class will need to use
 * \Cake\Event\EventDispatcherTrait to attach and detach on set and bind
 *
 * @see uim.cake.controllers.ComponentRegistry
 * @see uim.cake.View\HelperRegistry
 * @see uim.cake.Console\TaskRegistry
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
    protected $_loaded = [];

    /**
     * Loads/constructs an object instance.
     *
     * Will return the instance in the registry if it already exists.
     * If a subclass provides event support, you can use `$config["enabled"] = false`
     * to exclude constructed objects from being registered for events.
     *
     * Using {@link \Cake\Controller\Component::$components} as an example. You can alias
     * an object by setting the "className" key, i.e.,
     *
     * ```
     * protected $components = [
     *   "Email": [
     *     "className": "App\Controller\Component\AliasedEmailComponent"
     *   ];
     * ];
     * ```
     *
     * All calls to the `Email` component would use `AliasedEmail` instead.
     *
     * @param string $name The name/class of the object to load.
     * @param array<string, mixed> $config Additional settings to use when loading the object.
     * @return mixed
     * @psalm-return TObject
     * @throws \Exception If the class cannot be found.
     */
    function load(string $name, array $config = []) {
        if (isset($config["className"])) {
            $objName = $name;
            $name = $config["className"];
        } else {
            [, $objName] = pluginSplit($name);
        }

        $loaded = isset(_loaded[$objName]);
        if ($loaded && !empty($config)) {
            _checkDuplicate($objName, $config);
        }
        if ($loaded) {
            return _loaded[$objName];
        }

        $className = $name;
        if (is_string($name)) {
            $className = _resolveClassName($name);
            if ($className == null) {
                [$plugin, $name] = pluginSplit($name);
                _throwMissingClassError($name, $plugin);
            }
        }

        /**
         * @psalm-var TObject $instance
         * @psalm-suppress PossiblyNullArgument
         **/
        $instance = _create($className, $objName, $config);
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
     * @param string $name The name of the alias in the registry.
     * @param array<string, mixed> $config The config data for the new instance.
     * @return void
     * @throws \RuntimeException When a duplicate is found.
     */
    protected function _checkDuplicate(string $name, array $config): void
    {
        $existing = _loaded[$name];
        $msg = sprintf("The "%s" alias has already been loaded.", $name);
        $hasConfig = method_exists($existing, "getConfig");
        if (!$hasConfig) {
            throw new RuntimeException($msg);
        }
        if (empty($config)) {
            return;
        }
        $existingConfig = $existing.getConfig();
        unset($config["enabled"], $existingConfig["enabled"]);

        $failure = null;
        foreach ($config as $key: $value) {
            if (!array_key_exists($key, $existingConfig)) {
                $failure = " The `{$key}` was not defined in the previous configuration data.";
                break;
            }
            if (isset($existingConfig[$key]) && $existingConfig[$key] != $value) {
                $failure = sprintf(
                    " The `%s` key has a value of `%s` but previously had a value of `%s`",
                    $key,
                    json_encode($value),
                    json_encode($existingConfig[$key])
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
     * @param string $class The class to resolve.
     * @return string|null The resolved name or null for failure.
     * @psalm-return class-string|null
     */
    abstract protected function _resolveClassName(string $class): ?string;

    /**
     * Throw an exception when the requested object name is missing.
     *
     * @param string $class The class that is missing.
     * @param string|null $plugin The plugin $class is missing from.
     * @return void
     * @throws \Exception
     */
    abstract protected function _throwMissingClassError(string $class, ?string $plugin): void;

    /**
     * Create an instance of a given classname.
     *
     * This method should construct and do any other initialization logic
     * required.
     *
     * @param object|string $class The class to build.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config The Configuration settings for construction
     * @return object
     * @psalm-param TObject|string $class
     * @psalm-return TObject
     */
    abstract protected function _create($class, string $alias, array $config);

    /**
     * Get the list of loaded objects.
     *
     * @return array<string> List of object names.
     */
    string[] loaded(): array
    {
        return array_keys(_loaded);
    }

    /**
     * Check whether a given object is loaded.
     *
     * @param string $name The object name to check for.
     * @return bool True is object is loaded else false.
     */
    function has(string $name): bool
    {
        return isset(_loaded[$name]);
    }

    /**
     * Get loaded object instance.
     *
     * @param string $name Name of object.
     * @return object Object instance.
     * @throws \RuntimeException If not loaded or found.
     * @psalm-return TObject
     */
    function get(string $name) {
        if (!isset(_loaded[$name])) {
            throw new RuntimeException(sprintf("Unknown object "%s"", $name));
        }

        return _loaded[$name];
    }

    /**
     * Provide public read access to the loaded objects
     *
     * @param string $name Name of property to read
     * @return object|null
     * @psalm-return TObject|null
     */
    function __get(string $name) {
        return _loaded[$name] ?? null;
    }

    /**
     * Provide isset access to _loaded
     *
     * @param string $name Name of object being checked.
     * @return bool
     */
    function __isset(string $name): bool
    {
        return this.has($name);
    }

    /**
     * Sets an object.
     *
     * @param string $name Name of a property to set.
     * @param object $object Object to set.
     * @psalm-param TObject $object
     * @return void
     */
    function __set(string $name, $object): void
    {
        this.set($name, $object);
    }

    /**
     * Unsets an object.
     *
     * @param string $name Name of a property to unset.
     * @return void
     */
    function __unset(string $name): void
    {
        this.unload($name);
    }

    /**
     * Normalizes an object array, creates an array that makes lazy loading
     * easier
     *
     * @param array $objects Array of child objects to normalize.
     * @return array<string, array> Array of normalized objects.
     */
    function normalizeArray(array $objects): array
    {
        $normal = [];
        foreach ($objects as $i: $objectName) {
            $config = [];
            if (!is_int($i)) {
                $config = (array)$objectName;
                $objectName = $i;
            }
            [, $name] = pluginSplit($objectName);
            if (isset($config["class"])) {
                $normal[$name] = $config + ["config": []];
            } else {
                $normal[$name] = ["class": $objectName, "config": $config];
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
        foreach (array_keys(_loaded) as $name) {
            this.unload((string)$name);
        }

        return this;
    }

    /**
     * Set an object directly into the registry by name.
     *
     * If this collection : events, the passed object will
     * be attached into the event manager
     *
     * @param string $name The name of the object to set in the registry.
     * @param object $object instance to store in the registry
     * @return this
     * @psalm-param TObject $object
     * @psalm-suppress MoreSpecificReturnType
     */
    function set(string $name, object $object) {
        [, $objName] = pluginSplit($name);

        // Just call unload if the object was loaded before
        if (array_key_exists($name, _loaded)) {
            this.unload($name);
        }
        if (this instanceof EventDispatcherInterface && $object instanceof IEventListener) {
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
     * @param string $name The name of the object to remove from the registry.
     * @return this
     * @psalm-suppress MoreSpecificReturnType
     */
    function unload(string $name) {
        if (empty(_loaded[$name])) {
            [$plugin, $name] = pluginSplit($name);
            _throwMissingClassError($name, $plugin);
        }

        $object = _loaded[$name];
        if (this instanceof EventDispatcherInterface && $object instanceof IEventListener) {
            this.getEventManager().off($object);
        }
        unset(_loaded[$name]);

        /** @psalm-suppress LessSpecificReturnStatement */
        return this;
    }

    /**
     * Returns an array iterator.
     *
     * @return \Traversable
     * @psalm-return \Traversable<string, TObject>
     */
    function getIterator(): Traversable
    {
        return new ArrayIterator(_loaded);
    }

    /**
     * Returns the number of loaded objects.
     *
     * @return int
     */
    function count(): int
    {
        return count(_loaded);
    }

    /**
     * Debug friendly object properties.
     *
     * @return array<string, mixed>
     */
    function __debugInfo(): array
    {
        $properties = get_object_vars(this);
        if (isset($properties["_loaded"])) {
            $properties["_loaded"] = array_keys($properties["_loaded"]);
        }

        return $properties;
    }
}
