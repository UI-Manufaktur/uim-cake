

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs;

import uim.cake.core.App;
import uim.cake.core.ObjectRegistry;
use Psr\Log\LoggerInterface;
use RuntimeException;

/**
 * Registry of loaded log engines
 *
 * @extends \Cake\Core\ObjectRegistry<\Psr\Log\LoggerInterface>
 */
class LogEngineRegistry : ObjectRegistry
{
    /**
     * Resolve a logger classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve.
     * @return string|null Either the correct class name or null.
     * @psalm-return class-string|null
     */
    protected auto _resolveClassName(string myClass): Nullable!string
    {
        return App::className(myClass, 'Log/Engine', 'Log');
    }

    /**
     * Throws an exception when a logger is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the logger is missing in.
     * @return void
     * @throws \RuntimeException
     */
    protected auto _throwMissingClassError(string myClass, Nullable!string myPlugin): void
    {
        throw new RuntimeException(sprintf('Could not load class %s', myClass));
    }

    /**
     * Create the logger instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param \Psr\Log\LoggerInterface|string myClass The classname or object to make.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the logger.
     * @return \Psr\Log\LoggerInterface The constructed logger class.
     * @throws \RuntimeException when an object doesn't implement the correct interface.
     */
    protected auto _create(myClass, string myAlias, array myConfig): LoggerInterface
    {
        if (is_callable(myClass)) {
            myClass = myClass(myAlias);
        }

        if (is_object(myClass)) {
            $instance = myClass;
        }

        if (!isset($instance)) {
            /** @psalm-suppress UndefinedClass */
            $instance = new myClass(myConfig);
        }

        if ($instance instanceof LoggerInterface) {
            return $instance;
        }

        throw new RuntimeException(sprintf(
            'Loggers must implement %s. Found `%s` instance instead.',
            LoggerInterface::class,
            getTypeName($instance)
        ));
    }

    /**
     * Remove a single logger from the registry.
     *
     * @param string myName The logger name.
     * @return this
     */
    function unload(string myName) {
        unset(this._loaded[myName]);

        return this;
    }
}
