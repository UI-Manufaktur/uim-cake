module uim.cake.Mailer;

use BadMethodCallException;
import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
use RuntimeException;

/**
 * An object registry for mailer transports.
 *
 * @: uim.cake.Core\ObjectRegistry<uim.cake.mailers.AbstractTransport>
 */
class TransportRegistry : ObjectRegistry
{
    /**
     * Resolve a mailer tranport classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class Partial classname to resolve or transport instance.
     * @return string|null Either the correct classname or null.
     * @psalm-return class-string|null
     */
    protected function _resolveClassName(string $class): ?string
    {
        return App::className($class, "Mailer/Transport", "Transport");
    }

    /**
     * Throws an exception when a cache engine is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string $class The classname that is missing.
     * @param string|null $plugin The plugin the cache is missing in.
     * @return void
     * @throws \BadMethodCallException
     */
    protected function _throwMissingClassError(string $class, ?string $plugin): void
    {
        throw new BadMethodCallException(sprintf("Mailer transport %s is not available.", $class));
    }

    /**
     * Create the mailer transport instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param uim.cake.mailers.AbstractTransport|string $class The classname or object to make.
     * @param string $alias The alias of the object.
     * @param array<string, mixed> $config An array of settings to use for the cache engine.
     * @return uim.cake.mailers.AbstractTransport The constructed transport class.
     * @throws \RuntimeException when an object doesn"t implement the correct interface.
     */
    protected function _create($class, string $alias, array $config): AbstractTransport
    {
        if (is_object($class)) {
            $instance = $class;
        } else {
            $instance = new $class($config);
        }

        if ($instance instanceof AbstractTransport) {
            return $instance;
        }

        throw new RuntimeException(
            "Mailer transports must import uim.cake.mailers.AbstractTransport as a base class."
        );
    }

    /**
     * Remove a single adapter from the registry.
     *
     * @param string aName The adapter name.
     * @return this
     */
    function unload(string aName) {
        unset(_loaded[$name]);

        return this;
    }
}
