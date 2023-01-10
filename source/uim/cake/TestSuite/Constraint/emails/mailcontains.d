/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Email;

/**
 * MailContains
 *
 * @internal
 */
class MailContains : MailConstraintBase
{
    /**
     * Mail type to check contents of
     *
     */
    protected Nullable!string type;

    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     */
    bool matches($other) {
        $other = preg_quote($other, "/");
        $messages = this.getMessages();
        foreach ($messages as $message) {
            $method = this.getTypeMethod();
            $message = $message.$method();

            if (preg_match("/$other/", $message) > 0) {
                return true;
            }
        }

        return false;
    }

    /**
     */
    protected string getTypeMethod() {
        return "getBody" ~ (this.type ? ucfirst(this.type) : "String");
    }

    /**
     * Returns the type-dependent strings of all messages
     * respects this.at
     */
    protected string getAssertedMessages() {
        $messageMembers = null;
        $messages = this.getMessages();
        foreach ($messages as $message) {
            $method = this.getTypeMethod();
            $messageMembers[] = $message.$method();
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
            return sprintf("is in email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in an email" ~ this.getAssertedMessages();
    }
}
