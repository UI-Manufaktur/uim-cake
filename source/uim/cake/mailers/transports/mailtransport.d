

/**
 * Send mail using mail() function
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

import uim.cake.core.exceptions.CakeException;
import uim.cake.mailers.AbstractTransport;
import uim.cake.mailers.Message;

/**
 * Send mail using mail() function
 */
class MailTransport : AbstractTransport
{

    array send(Message $message) {
        this.checkRecipient($message);

        // https://github.com/cakephp/cakephp/issues/2209
        // https://bugs.php.net/bug.php?id=47983
        $subject = str_replace("\r\n", "", $message.getSubject());

        $to = $message.getHeaders(["to"])["To"];
        $to = str_replace("\r\n", "", $to);

        $eol = this.getConfig("eol", version_compare(PHP_VERSION, "8.0", ">=") ? "\r\n" : "\n");
        $headers = $message.getHeadersString(
            [
                "from",
                "sender",
                "replyTo",
                "readReceipt",
                "returnPath",
                "cc",
                "bcc",
            ],
            $eol,
            function ($val) {
                return str_replace("\r\n", "", $val);
            }
        );

        $message = $message.getBodyString($eol);

        $params = this.getConfig("additionalParameters", "");
        _mail($to, $subject, $message, $headers, $params);

        $headers .= $eol ~ "To: " ~ $to;
        $headers .= $eol ~ "Subject: " ~ $subject;

        return ["headers": $headers, "message": $message];
    }

    /**
     * Wraps internal function mail() and throws exception instead of errors if anything goes wrong
     *
     * @param string $to email"s recipient
     * @param string $subject email"s subject
     * @param string $message email"s body
     * @param string $headers email"s custom headers
     * @param string $params additional params for sending email
     * @throws uim.cake.Network\exceptions.SocketException if mail could not be sent
     */
    protected void _mail(
        string $to,
        string $subject,
        string $message,
        string $headers = "",
        string $params = ""
    ) {
        // phpcs:disable
        if (!@mail($to, $subject, $message, $headers, $params)) {
            $error = error_get_last();
            $msg = "Could not send email: " ~ ($error["message"] ?? "unknown");
            throw new CakeException($msg);
        }
        // phpcs:enable
    }
}
