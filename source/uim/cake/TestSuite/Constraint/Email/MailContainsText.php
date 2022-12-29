


 *


 * @since         3.7.0
  */
module uim.cake.TestSuite\Constraint\Email;

import uim.cake.Mailer\Message;

/**
 * MailContainsText
 *
 * @internal
 */
class MailContainsText : MailContains
{

    protected $type = Message::MESSAGE_TEXT;

    /**
     * Assertion message string
     *
     * @return string
     */
    string toString(): string
    {
        if (this.at) {
            return sprintf("is in the text message of email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in the text message of an email" . this.getAssertedMessages();
    }
}
