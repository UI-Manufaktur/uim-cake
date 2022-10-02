

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.7.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite\Constraint\Email;

/**
 * MailContains
 *
 * @internal
 */
class MailContains : MailConstraintBase
{
    /**
     * Mail type to check contents of
     *
     * @var string|null
     */
    protected myType;

    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        $other = preg_quote($other, '/');
        myMessages = this.getMessages();
        foreach (myMessages as myMessage) {
            $method = this.getTypeMethod();
            myMessage = myMessage.$method();

            if (preg_match("/$other/", myMessage) > 0) {
                return true;
            }
        }

        return false;
    }

    /**
     * @return string
     */
    protected auto getTypeMethod(): string
    {
        return 'getBody' . (this.type ? ucfirst(this.type) : 'String');
    }

    /**
     * Returns the type-dependent strings of all messages
     * respects this.at
     *
     * @return string
     */
    protected auto getAssertedMessages(): string
    {
        myMessageMembers = [];
        myMessages = this.getMessages();
        foreach (myMessages as myMessage) {
            $method = this.getTypeMethod();
            myMessageMembers[] = myMessage.$method();
        }
        if (this.at && isset(myMessageMembers[this.at - 1])) {
            myMessageMembers = [myMessageMembers[this.at - 1]];
        }
        myResult = implode(PHP_EOL, myMessageMembers);

        return PHP_EOL . 'was: ' . mb_substr(myResult, 0, 1000);
    }

    /**
     * Assertion message string
     *
     * @return string
     */
    function toString(): string
    {
        if (this.at) {
            return sprintf('is in email #%d', this.at) . this.getAssertedMessages();
        }

        return 'is in an email' . this.getAssertedMessages();
    }
}
