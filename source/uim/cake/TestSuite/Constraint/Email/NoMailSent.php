


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
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
     * @return bool
     */
    function matches($other): bool
    {
        return count(this.getMessages()) == 0;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        return 'no emails were sent';
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected function failureDescription($other): string
    {
        return this.toString();
    }
}
