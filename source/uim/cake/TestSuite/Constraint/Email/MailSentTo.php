


 *


 * @since         3.7.0
  */
module uim.cake.TestSuite\Constraint\Email;

/**
 * MailSentTo
 *
 * @internal
 */
class MailSentTo : MailSentWith
{
    /**
     * @var string
     */
    protected $method = "to";

    /**
     * Assertion message string
     *
     * @return string
     */
    string toString()
    {
        if (this.at) {
            return sprintf("was sent email #%d", this.at);
        }

        return "was sent an email";
    }
}
