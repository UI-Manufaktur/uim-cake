

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Constraint\Email;

import uim.cake.Mailer\Message;

/**
 * MailContainsText
 *
 * @internal
 */
class MailContainsText : MailContains
{

    protected myType = Message::MESSAGE_TEXT;

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is in the text message of email #%d', this.at) . this.getAssertedMessages();
        }

        return 'is in the text message of an email' . this.getAssertedMessages();
    }
}
