

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Constraint\Email;

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
        return count(this.getMessages()) === $other;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        return 'emails were sent';
    }
}
