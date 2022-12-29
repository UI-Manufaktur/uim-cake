


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Mailer;

import uim.cake.cores.exceptions.CakeException;
import uim.cake.cores.InstanceConfigTrait;

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
     * @param \Cake\Mailer\Message $message Email message.
     * @return array
     * @psalm-return array{headers: string, message: string}
     */
    abstract function send(Message $message): array;

    /**
     * Constructor
     *
     * @param array<string, mixed> $config Configuration options.
     */
    public this(array $config = []) {
        this.setConfig($config);
    }

    /**
     * Check that at least one destination header is set.
     *
     * @param \Cake\Mailer\Message $message Message instance.
     * @return void
     * @throws \Cake\Core\Exception\CakeException If at least one of to, cc or bcc is not specified.
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
                . " Use one of `setTo`, `setCc` or `setBcc` to define a recipient."
            );
        }
    }
}
