

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Constraint\Email;

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
    protected $method = 'from';

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('sent email #%d', this.at);
        }

        return 'sent an email';
    }
}
