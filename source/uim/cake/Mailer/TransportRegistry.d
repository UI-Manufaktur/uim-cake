

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Mailer;

use BadMethodCallException;
import uim.baklava.core.App;
import uim.baklava.core.ObjectRegistry;
use RuntimeException;

/**
 * An object registry for mailer transports.
 *
 * @extends \Cake\Core\ObjectRegistry<\Cake\Mailer\AbstractTransport>
 */
class TransportRegistry : ObjectRegistry
{
    /**
     * Resolve a mailer tranport classname.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass Partial classname to resolve or transport instance.
     * @return string|null Either the correct classname or null.
     * @psalm-return class-string|null
     */
    protected auto _resolveClassName(string myClass): ?string
    {
        return App::className(myClass, 'Mailer/Transport', 'Transport');
    }

    /**
     * Throws an exception when a cache engine is missing.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param string myClass The classname that is missing.
     * @param string|null myPlugin The plugin the cache is missing in.
     * @return void
     * @throws \BadMethodCallException
     */
    protected auto _throwMissingClassError(string myClass, ?string myPlugin): void
    {
        throw new BadMethodCallException(sprintf('Mailer transport %s is not available.', myClass));
    }

    /**
     * Create the mailer transport instance.
     *
     * Part of the template method for Cake\Core\ObjectRegistry::load()
     *
     * @param \Cake\Mailer\AbstractTransport|string myClass The classname or object to make.
     * @param string myAlias The alias of the object.
     * @param array<string, mixed> myConfig An array of settings to use for the cache engine.
     * @return \Cake\Mailer\AbstractTransport The constructed transport class.
     * @throws \RuntimeException when an object doesn't implement the correct interface.
     */
    protected auto _create(myClass, string myAlias, array myConfig): AbstractTransport
    {
        if (is_object(myClass)) {
            $instance = myClass;
        } else {
            $instance = new myClass(myConfig);
        }

        if ($instance instanceof AbstractTransport) {
            return $instance;
        }

        throw new RuntimeException(
            'Mailer transports must import uim.baklava.Mailer\AbstractTransport as a base class.'
        );
    }

    /**
     * Remove a single adapter from the registry.
     *
     * @param string myName The adapter name.
     * @return this
     */
    function unload(string myName) {
        unset(this._loaded[myName]);

        return this;
    }
}
