module uim.cake.Mailer;

import uim.cake.core.StaticConfigTrait;
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
     * @var uim.cake.mailers.TransportRegistry|null
     */
    protected static _registry;

    /**
     * An array mapping url schemes to fully qualified Transport class names
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string>
     */
    protected static _dsnClassMap = [
        "debug": Transport\DebugTransport::class,
        "mail": Transport\MailTransport::class,
        "smtp": Transport\SmtpTransport::class,
    ];

    /**
     * Returns the Transport Registry used for creating and using transport instances.
     *
     * @return uim.cake.mailers.TransportRegistry
     */
    static function getRegistry(): TransportRegistry
    {
        if (static::_registry == null) {
            static::_registry = new TransportRegistry();
        }

        return static::_registry;
    }

    /**
     * Sets the Transport Registry instance used for creating and using transport instances.
     *
     * Also allows for injecting of a new registry instance.
     *
     * @param uim.cake.mailers.TransportRegistry $registry Injectable registry object.
     */
    static void setRegistry(TransportRegistry $registry) {
        static::_registry = $registry;
    }

    /**
     * Finds and builds the instance of the required tranport class.
     *
     * @param string aName Name of the config array that needs a tranport instance built
     * @return void
     * @throws \InvalidArgumentException When a tranport cannot be created.
     */
    protected static void _buildTransport(string aName) {
        if (!isset(static::_config[$name])) {
            throw new InvalidArgumentException(
                sprintf("The '%s' transport configuration does not exist", $name)
            );
        }

        if (is_array(static::_config[$name]) && empty(static::_config[$name]["className"])) {
            throw new InvalidArgumentException(
                sprintf("Transport config '%s' is invalid, the required `className` option is missing", $name)
            );
        }

        /** @phpstan-ignore-next-line */
        static::getRegistry().load($name, static::_config[$name]);
    }

    /**
     * Get transport instance.
     *
     * @param string aName Config name.
     * @return uim.cake.mailers.AbstractTransport
     */
    static function get(string aName): AbstractTransport
    {
        $registry = static::getRegistry();

        if (isset($registry.{$name})) {
            return $registry.{$name};
        }

        static::_buildTransport($name);

        return $registry.{$name};
    }
}
