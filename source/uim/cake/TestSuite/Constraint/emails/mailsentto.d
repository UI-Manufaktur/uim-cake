module uim.cake.TestSuite\Constraint\Email;

/**
 * MailSentTo
 *
 * @internal
 */
class MailSentTo : MailSentWith
{
    /**
     */
    protected string $method = "to";

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("was sent email #%d", this.at);
        }

        return "was sent an email";
    }
}
