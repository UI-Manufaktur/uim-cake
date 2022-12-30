


 *


 * @since         3.7.0
  */
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
     * @return bool
     */
    function matches($other): bool
    {
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
     * @return string
     */
    protected function getTypeMethod(): string
    {
        return "getBody" . (this.type ? ucfirst(this.type) : "String");
    }

    /**
     * Returns the type-dependent strings of all messages
     * respects this.at
     *
     * @return string
     */
    protected function getAssertedMessages(): string
    {
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

        return PHP_EOL . "was: " . mb_substr($result, 0, 1000);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    string toString()
    {
        if (this.at) {
            return sprintf("is in email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in an email" . this.getAssertedMessages();
    }
}
