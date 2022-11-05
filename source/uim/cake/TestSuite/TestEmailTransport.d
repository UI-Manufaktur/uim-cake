

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.Mailer\Message;
import uim.baklava.Mailer\Transport\DebugTransport;
import uim.baklava.Mailer\TransportFactory;

/**
 * TestEmailTransport
 *
 * Set this as the email transport to capture emails for later assertions
 *
 * @see \Cake\TestSuite\EmailTrait
 */
class TestEmailTransport : DebugTransport
{
    /**
     * @var array
     */
    private static myMessages = [];

    /**
     * Stores email for later assertions
     *
     * @param \Cake\Mailer\Message myMessage Message
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    function send(Message myMessage): array
    {
        static::myMessages[] = myMessage;

        return super.send(myMessage);
    }

    /**
     * Replaces all currently configured transports with this one
     *
     * @return void
     */
    static function replaceAllTransports(): void
    {
        myConfiguredTransports = TransportFactory::configured();

        foreach (myConfiguredTransports as myConfiguredTransport) {
            myConfig = TransportFactory::getConfig(myConfiguredTransport);
            myConfig['className'] = self::class;
            TransportFactory::drop(myConfiguredTransport);
            TransportFactory::setConfig(myConfiguredTransport, myConfig);
        }
    }

    /**
     * Gets emails sent
     *
     * @return array<\Cake\Mailer\Message>
     */
    static auto getMessages() {
        return static::myMessages;
    }

    /**
     * Clears list of emails that have been sent
     *
     * @return void
     */
    static function clearMessages(): void
    {
        static::myMessages = [];
    }
}
