

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Mailer;

import uim.baklava.core.StaticConfigTrait;
use InvalidArgumentException;

/**
 * Factory class for generating email transport instances.
 */
class TransportFactory
{
    use StaticConfigTrait;

    /**
     * Transport Registry used for creating and using transport instances.
     *
     * @var \Cake\Mailer\TransportRegistry|null
     */
    protected static $_registry;

    /**
     * An array mapping url schemes to fully qualified Transport class names
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string>
     */
    protected static $_dsnClassMap = [
        'debug' => Transport\DebugTransport::class,
        'mail' => Transport\MailTransport::class,
        'smtp' => Transport\SmtpTransport::class,
    ];

    /**
     * Returns the Transport Registry used for creating and using transport instances.
     *
     * @return \Cake\Mailer\TransportRegistry
     */
    static auto getRegistry(): TransportRegistry
    {
        if (static::$_registry === null) {
            static::$_registry = new TransportRegistry();
        }

        return static::$_registry;
    }

    /**
     * Sets the Transport Registry instance used for creating and using transport instances.
     *
     * Also allows for injecting of a new registry instance.
     *
     * @param \Cake\Mailer\TransportRegistry $registry Injectable registry object.
     * @return void
     */
    static auto setRegistry(TransportRegistry $registry): void
    {
        static::$_registry = $registry;
    }

    /**
     * Finds and builds the instance of the required tranport class.
     *
     * @param string myName Name of the config array that needs a tranport instance built
     * @return void
     * @throws \InvalidArgumentException When a tranport cannot be created.
     */
    protected static auto _buildTransport(string myName): void
    {
        if (!isset(static::$_config[myName])) {
            throw new InvalidArgumentException(
                sprintf('The "%s" transport configuration does not exist', myName)
            );
        }

        if (is_array(static::$_config[myName]) && empty(static::$_config[myName]['className'])) {
            throw new InvalidArgumentException(
                sprintf('Transport config "%s" is invalid, the required `className` option is missing', myName)
            );
        }

        static::getRegistry().load(myName, static::$_config[myName]);
    }

    /**
     * Get transport instance.
     *
     * @param string myName Config name.
     * @return \Cake\Mailer\AbstractTransport
     */
    static auto get(string myName): AbstractTransport
    {
        $registry = static::getRegistry();

        if (isset($registry.{myName})) {
            return $registry.{myName};
        }

        static::_buildTransport(myName);

        return $registry.{myName};
    }
}
