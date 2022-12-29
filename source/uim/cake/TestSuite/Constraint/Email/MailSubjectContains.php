


 *


 * @since         4.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Email;

use InvalidArgumentException;

/**
 * MailSubjectContains
 *
 * @internal
 */
class MailSubjectContains : MailConstraintBase
{
    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        if (!is_string($other)) {
            throw new InvalidArgumentException(
                "Invalid data type, must be a string."
            );
        }
        $messages = this.getMessages();
        foreach ($messages as $message) {
            $subject = $message.getOriginalSubject();
            if (strpos($subject, $other) != false) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns the subjects of all messages
     * respects this.at
     *
     * @return string
     */
    protected function getAssertedMessages(): string
    {
        $messageMembers = [];
        $messages = this.getMessages();
        foreach ($messages as $message) {
            $messageMembers[] = $message.getSubject();
        }
        if (this.at && isset($messageMembers[this.at - 1])) {
            $messageMembers = [$messageMembers[this.at - 1]];
        }
        $result = implode(PHP_EOL, $messageMembers);

        return PHP_EOL . "was: " . mb_substr($result, 0, 1000);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf("is in an email subject #%d", this.at) . this.getAssertedMessages();
        }

        return "is in an email subject" . this.getAssertedMessages();
    }
}
