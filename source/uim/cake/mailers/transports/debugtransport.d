

/**
 * Emulates the message sending process for testing purposes
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.0.0
  */module uim.cake.mailers.Transport;

import uim.cake.mailers.AbstractTransport;
import uim.cake.mailers.Message;

/**
 * Debug Transport class, useful for emulating the email sending process and inspecting
 * the resultant email message before actually sending it during development
 */
class DebugTransport : AbstractTransport
{

    function send(Message $message): array
    {
        $headers = $message.getHeadersString(
            ["from", "sender", "replyTo", "readReceipt", "returnPath", "to", "cc", "subject"]
        );
        $message = implode("\r\n", $message.getBody());

        return ["headers": $headers, "message": $message];
    }
}
