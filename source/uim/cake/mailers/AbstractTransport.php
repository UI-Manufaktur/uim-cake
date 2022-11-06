module uim.cake.Mailer;

import uim.cake.core.exceptions\CakeException;
import uim.cake.core.InstanceConfigTrait;

/**
 * Abstract transport for sending email
 */
abstract class AbstractTransport
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [];

    /**
     * Send mail
     *
     * @param \Cake\Mailer\Message myMessage Email message.
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    abstract function send(Message myMessage): array;

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Configuration options.
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }

    /**
     * Check that at least one destination header is set.
     *
     * @param \Cake\Mailer\Message myMessage Message instance.
     * @return void
     * @throws \Cake\Core\Exception\CakeException If at least one of to, cc or bcc is not specified.
     */
    protected auto checkRecipient(Message myMessage): void
    {
        if (
            myMessage.getTo() === []
            && myMessage.getCc() === []
            && myMessage.getBcc() === []
        ) {
            throw new CakeException(
                'You must specify at least one recipient.'
                . ' Use one of `setTo`, `setCc` or `setBcc` to define a recipient.'
            );
        }
    }
}
