module uim.cake.TestSuite;

import uim.cake.Mailer\Message;
import uim.cake.Mailer\Transport\DebugTransport;
import uim.cake.Mailer\TransportFactory;

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
    private static $messages = [];

    /**
     * Stores email for later assertions
     *
     * @param uim.cake.Mailer\Message $message Message
     * @return array{headers: string, message: string}
     */
    function send(Message $message): array
    {
        static::$messages[] = $message;

        return parent::send($message);
    }

    /**
     * Replaces all currently configured transports with this one
     *
     */
    static void replaceAllTransports(): void
    {
        $configuredTransports = TransportFactory::configured();

        foreach ($configuredTransports as $configuredTransport) {
            $config = TransportFactory::getConfig($configuredTransport);
            $config["className"] = self::class;
            TransportFactory::drop($configuredTransport);
            TransportFactory::setConfig($configuredTransport, $config);
        }
    }

    /**
     * Gets emails sent
     *
     * @return array<uim.cake.Mailer\Message>
     */
    static function getMessages() {
        return static::$messages;
    }

    /**
     * Clears list of emails that have been sent
     *
     */
    static void clearMessages(): void
    {
        static::$messages = [];
    }
}
