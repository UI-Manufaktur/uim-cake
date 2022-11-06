

/**
 * Send mail using mail() function
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Mailer\Transport;

import uim.cake.core.exceptions\CakeException;
import uim.cake.Mailer\AbstractTransport;
import uim.cake.Mailer\Message;

/**
 * Send mail using mail() function
 */
class MailTransport : AbstractTransport
{

    function send(Message myMessage): array
    {
        this.checkRecipient(myMessage);

        // https://github.com/cakephp/cakephp/issues/2209
        // https://bugs.php.net/bug.php?id=47983
        $subject = str_replace("\r\n", '', myMessage.getSubject());

        $to = myMessage.getHeaders(['to'])['To'];
        $to = str_replace("\r\n", '', $to);

        $eol = this.getConfig('eol', version_compare(PHP_VERSION, '8.0', '>=') ? "\r\n" : "\n");
        $headers = myMessage.getHeadersString(
            [
                'from',
                'sender',
                'replyTo',
                'readReceipt',
                'returnPath',
                'cc',
                'bcc',
            ],
            $eol,
            function ($val) {
                return str_replace("\r\n", '', $val);
            }
        );

        myMessage = myMessage.getBodyString($eol);

        myParams = this.getConfig('additionalParameters', '');
        this._mail($to, $subject, myMessage, $headers, myParams);

        $headers .= $eol . 'To: ' . $to;
        $headers .= $eol . 'Subject: ' . $subject;

        return ['headers' => $headers, 'message' => myMessage];
    }

    /**
     * Wraps internal function mail() and throws exception instead of errors if anything goes wrong
     *
     * @param string $to email's recipient
     * @param string $subject email's subject
     * @param string myMessage email's body
     * @param string $headers email's custom headers
     * @param string myParams additional params for sending email
     * @throws \Cake\Network\Exception\SocketException if mail could not be sent
     * @return void
     */
    protected auto _mail(
        string $to,
        string $subject,
        string myMessage,
        string $headers = '',
        string myParams = ''
    ): void {
        // phpcs:disable
        if (!@mail($to, $subject, myMessage, $headers, myParams)) {
            myError = error_get_last();
            $msg = 'Could not send email: ' . (myError['message'] ?? 'unknown');
            throw new CakeException($msg);
        }
        // phpcs:enable
    }
}
