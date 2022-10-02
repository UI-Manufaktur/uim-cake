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
                'Invalid data type, must be a string.'
            );
        }
        myMessages = this.getMessages();
        foreach (myMessages as myMessage) {
            $subject = myMessage.getOriginalSubject();
            if (strpos($subject, $other) !== false) {
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
    protected auto getAssertedMessages(): string
    {
        myMessageMembers = [];
        myMessages = this.getMessages();
        foreach (myMessages as myMessage) {
            myMessageMembers[] = myMessage.getSubject();
        }
        if (this.at && isset(myMessageMembers[this.at - 1])) {
            myMessageMembers = [myMessageMembers[this.at - 1]];
        }
        myResult = implode(PHP_EOL, myMessageMembers);

        return PHP_EOL . 'was: ' . mb_substr(myResult, 0, 1000);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is in an email subject #%d', this.at) . this.getAssertedMessages();
        }

        return 'is in an email subject' . this.getAssertedMessages();
    }
}
