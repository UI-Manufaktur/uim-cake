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
     */
    string toString()
    {
        if (this.at) {
            return sprintf("is in the text message of email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in the text message of an email" . this.getAssertedMessages();
    }
}
