/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.logs;
module uim.cake.Log;

import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
use Psr\logs.LoggerInterface;
use RuntimeException;

/**
 * Registry of loaded log engines
 *
 * @: uim.cake.Core\ObjectRegistry<\Psr\logs.LoggerInterface>
 */
class LogEngineRegistry : ObjectRegistry
{
    /**
     * Resolve a logger classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "Log/Engine", "Log");
    }

    /**
     * Throws an exception when a logger is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the logger is missing in.
     * @return void
     * @throws \RuntimeException
     */
    protected void _throwMissingClassError(string $class, ?string $plugin) {
        throw new RuntimeException(sprintf("Could not load class %s", $class));
    }

    /**
     * Create the logger instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param \Psr\logs.LoggerInterface|string $class The classname or object to make.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config An array of settings to use for the logger.
     * @return \Psr\logs.LoggerInterface The constructed logger class.
     * @throws \RuntimeException when an object doesn"t implement the correct interface.
     */
    protected function _create($class, string $alias, array $config): LoggerInterface
    {
        if (is_callable($class)) {
            $class = $class($alias);
        }

        if (is_object($class)) {
            $instance = $class;
        }

        if (!isset($instance)) {
            /** @psalm-suppress UndefinedClass */
            $instance = new $class($config);
        }

        if ($instance instanceof LoggerInterface) {
            return $instance;
        }

        throw new RuntimeException(sprintf(
            "Loggers must implement %s. Found `%s` instance instead.",
            LoggerInterface::class,
            getTypeName($instance)
        ));
    }

    /**
     * Remove a single logger from the registry.
     *
     * @param string aName The logger name.
     * @return this
     */
    function unload(string aName) {
        unset(_loaded[$name]);

        return this;
    }
}
