module uim.cake.TestSuite\Constraint\Email;

/**
 * NoMailSent
 *
 * @internal
 */
class NoMailSent : MailConstraintBase
{
    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     */
    bool matches($other) {
        return count(this.getMessages()) == 0;
    }

    /**
     * Assertion message string
     */
    string toString() {
        return "no emails were sent";
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other): string
    {
        return this.toString();
    }
}
