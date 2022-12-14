module uim.cake.TestSuite;

import uim.cake.mailers.Message;
import uim.cake.mailers.Transport\DebugTransport;
import uim.cake.mailers.TransportFactory;

/**
 * TestEmailTransport
 *
 * Set this as the email transport to capture emails for later assertions
 *
 * @see uim.cake.TestSuite\EmailTrait
 */
class TestEmailTransport : DebugTransport
{
    /**
     * @var array
     */
    private static $messages = null;

    /**
     * Stores email for later assertions
     *
     * @param uim.cake.mailers.Message $message Message
     * @return array{headers: string, message: string}
     */
    array send(Message $message) {
        static::$messages[] = $message;

        return super.send($message);
    }

    /**
     * Replaces all currently configured transports with this one
     */
    static void replaceAllTransports() {
        $configuredTransports = TransportFactory::configured();

        foreach ($configuredTransports as $configuredTransport) {
            aConfig = TransportFactory::getConfig($configuredTransport);
            aConfig["className"] = self::class;
            TransportFactory::drop($configuredTransport);
            TransportFactory::setConfig($configuredTransport, aConfig);
        }
    }

    /**
     * Gets emails sent
     *
     * @return array<uim.cake.mailers.Message>
     */
    static function getMessages() {
        return static::$messages;
    }

    /**
     * Clears list of emails that have been sent
     */
    static void clearMessages() {
        static::$messages = null;
    }
}
