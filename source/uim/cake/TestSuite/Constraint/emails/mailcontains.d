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
     * @var string|null
     */
    protected $type;

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
        $messageMembers = [];
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