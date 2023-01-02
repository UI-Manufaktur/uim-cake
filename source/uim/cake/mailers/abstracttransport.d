module uim.cake.Mailer;

import uim.cake.core.exceptions.CakeException;
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
     * @param uim.cake.mailers.Message $message Email message.
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    abstract function send(Message $message): array;

    /**
     * Constructor
     *
     * @param array<string, mixed> $config Configuration options.
     */
    this(array $config = []) {
        this.setConfig($config);
    }

    /**
     * Check that at least one destination header is set.
     *
     * @param uim.cake.mailers.Message $message Message instance.
     * @return void
     * @throws uim.cake.Core\exceptions.CakeException If at least one of to, cc or bcc is not specified.
     */
    protected function checkRecipient(Message $message): void
    {
        if (
            $message.getTo() == []
            && $message.getCc() == []
            && $message.getBcc() == []
        ) {
            throw new CakeException(
                "You must specify at least one recipient."
                ~ " Use one of `setTo`, `setCc` or `setBcc` to define a recipient."
            );
        }
    }
}
