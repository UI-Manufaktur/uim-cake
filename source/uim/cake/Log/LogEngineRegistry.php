


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Log;

import uim.cake.cores.App;
import uim.cake.cores.ObjectRegistry;
use Psr\Log\LoggerInterface;
use RuntimeException;

/**
 * Registry of loaded log engines
 *
 * @: \Cake\Core\ObjectRegistry<\Psr\Log\LoggerInterface>
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
    protected function _throwMissingClassError(string $class, ?string $plugin): void
    {
        throw new RuntimeException(sprintf("Could not load class %s", $class));
    }

    /**
     * Create the logger instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param \Psr\Log\LoggerInterface|string $class The classname or object to make.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config An array of settings to use for the logger.
     * @return \Psr\Log\LoggerInterface The constructed logger class.
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
     * @param string $name The logger name.
     * @return this
     */
    function unload(string $name) {
        unset(_loaded[$name]);

        return this;
    }
}
