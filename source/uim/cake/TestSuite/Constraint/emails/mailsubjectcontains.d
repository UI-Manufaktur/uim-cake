/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
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
     */
    bool matches($other) {
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
     */
    protected string getAssertedMessages() {
        $messageMembers = null;
        $messages = this.getMessages();
        foreach ($messages as $message) {
            $messageMembers[] = $message.getSubject();
        }
        if (this.at && isset($messageMembers[this.at - 1])) {
            $messageMembers = [$messageMembers[this.at - 1]];
        }
        $result = implode(PHP_EOL, $messageMembers);

        return PHP_EOL ~ "was: " ~ mb_substr($result, 0, 1000);
    }

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("is in an email subject #%d", this.at) . this.getAssertedMessages();
        }

        return "is in an email subject" ~ this.getAssertedMessages();
    }
}
