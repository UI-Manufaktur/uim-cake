


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Email;

import uim.cake.Mailer\Message;

/**
 * MailContainsHtml
 *
 * @internal
 */
class MailContainsHtml : MailContains
{
    /**
     * @inheritDoc
     */
    protected $type = Message::MESSAGE_HTML;

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf("is in the html message of email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in the html message of an email" . this.getAssertedMessages();
    }
}
