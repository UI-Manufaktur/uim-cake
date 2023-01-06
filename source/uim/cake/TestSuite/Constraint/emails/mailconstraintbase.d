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
    this(Nullable!int $at = null) {
        this.at = $at;
    }

    /**
     * Gets the email or emails to check
     *
     * @return array<uim.cake.mailers.Message>
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
