module uim.cake.TestSuite\Constraint\Email;

/**
 * MailCount
 *
 * @internal
 */
class MailCount : MailConstraintBase
{
    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        return count(this.getMessages()) == $other;
    }

    /**
     * Assertion message string
     */
    string toString()
    {
        return "emails were sent";
    }
}
