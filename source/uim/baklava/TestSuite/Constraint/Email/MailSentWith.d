

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Email;

/**
 * MailSentWith
 *
 * @internal
 */
class MailSentWith : MailConstraintBase
{
    /**
     * @var string
     */
    protected $method;

    /**
     * Constructor
     *
     * @param int|null $at At
     * @param string|null $method Method
     * @return void
     */
    this(Nullable!int $at = null, Nullable!string $method = null) {
        if ($method !== null) {
            this.method = $method;
        }

        super.this($at);
    }

    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        $emails = this.getMessages();
        foreach ($emails as $email) {
            myValue = $email.{'get' . ucfirst(this.method)}();
            if (
                in_array(this.method, ['to', 'cc', 'bcc', 'from', 'replyTo', 'sender'], true)
                && array_key_exists($other, myValue)
            ) {
                return true;
            }
            if (myValue === $other) {
                return true;
            }
        }

        return false;
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is in email #%d `%s`', this.at, this.method);
        }

        return sprintf('is in an email `%s`', this.method);
    }
}