


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Email;

import uim.cake.TestSuite\TestEmailTransport;
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
    public this(?int $at = null) {
        this.at = $at;
    }

    /**
     * Gets the email or emails to check
     *
     * @return array<\Cake\Mailer\Message>
     */
    function getMessages() {
        $messages = TestEmailTransport::getMessages();

        if (this.at != null) {
            if (!isset($messages[this.at])) {
                return [];
            }

            return [$messages[this.at]];
        }

        return $messages;
    }
}
