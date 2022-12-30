module uim.cake.TestSuite\Constraint\Email;

/**
 * MailSentFromConstraint
 *
 * @internal
 */
class MailSentFrom : MailSentWith
{
    /**
     * @var string
     */
    protected $method = "from";

    /**
     * Assertion message string
     */
    string toString()
    {
        if (this.at) {
            return sprintf("sent email #%d", this.at);
        }

        return "sent an email";
    }
}
