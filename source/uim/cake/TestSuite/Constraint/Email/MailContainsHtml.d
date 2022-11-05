

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Email;

import uim.baklava.Mailer\Message;

/**
 * MailContainsHtml
 *
 * @internal
 */
class MailContainsHtml : MailContains
{

    protected myType = Message::MESSAGE_HTML;

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is in the html message of email #%d', this.at) . this.getAssertedMessages();
        }

        return 'is in the html message of an email' . this.getAssertedMessages();
    }
}
