

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Email;

import uim.baklava.TestSuite\TestEmailTransport;
use PHPUnit\Framework\Constraint\Constraint;

/**
 * Base class for all mail assertion constraints
 *
 * @internal
 */
abstract class MailConstraintBase : Constraint
{
    /**
     * @var int|null
     */
    protected $at;

    /**
     * Constructor
     *
     * @param int|null $at At
     * @return void
     */
    this(?int $at = null) {
        this.at = $at;
    }

    /**
     * Gets the email or emails to check
     *
     * @return array<\Cake\Mailer\Message>
     */
    auto getMessages() {
        myMessages = TestEmailTransport::getMessages();

        if (this.at !== null) {
            if (!isset(myMessages[this.at])) {
                return [];
            }

            return [myMessages[this.at]];
        }

        return myMessages;
    }
}
