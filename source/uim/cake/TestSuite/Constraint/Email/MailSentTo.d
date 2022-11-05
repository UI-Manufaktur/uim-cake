

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Email;

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
    protected $method = 'to';

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('was sent email #%d', this.at);
        }

        return 'was sent an email';
    }
}
