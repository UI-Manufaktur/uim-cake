module uim.cake.TestSuite\Constraint\Email;

import uim.cake.Mailer\Message;

/**
 * MailContainsHtml
 *
 * @internal
 */
class MailContainsHtml : MailContains
{

    protected $type = Message::MESSAGE_HTML;

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("is in the html message of email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in the html message of an email" . this.getAssertedMessages();
    }
}
