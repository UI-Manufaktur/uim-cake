

/**
 * Emulates the message sending process for testing purposes
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cakeiler\Transport;

import uim.cakeiler\AbstractTransport;
import uim.cakeiler\Message;

/**
 * Debug Transport class, useful for emulating the email sending process and inspecting
 * the resultant email message before actually sending it during development
 */
class DebugTransport : AbstractTransport
{

    function send(Message myMessage): array
    {
        $headers = myMessage.getHeadersString(
            ['from', 'sender', 'replyTo', 'readReceipt', 'returnPath', 'to', 'cc', 'subject']
        );
        myMessage = implode("\r\n", myMessage.getBody());

        return ['headers' => $headers, 'message' => myMessage];
    }
}
