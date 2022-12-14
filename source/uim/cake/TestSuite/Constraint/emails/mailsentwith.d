/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Email;

/**
 * MailSentWith
 *
 * @internal
 */
class MailSentWith : MailConstraintBase
{
    /**
     */
    protected string $method;

    /**
     * Constructor
     *
     * @param int|null $at At
     * @param string|null $method Method
     * @return void
     */
    this(Nullable!int $at = null, Nullable!string $method = null) {
        if ($method != null) {
            this.method = $method;
        }

        super(($at);
    }

    /**
     * Checks constraint
     *
     * @param mixed $other Constraint check
     */
    bool matches($other) {
        $emails = this.getMessages();
        foreach ($emails as $email) {
            $value = $email.{"get" ~ ucfirst(this.method)}();
            if ($value == $other) {
                return true;
            }
            if (
                !is_array($other)
                && hasAllValues(this.method, ["to", "cc", "bcc", "from", "replyTo", "sender"])
                && array_key_exists($other, $value)
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("is in email #%d `%s`", this.at, this.method);
        }

        return sprintf("is in an email `%s`", this.method);
    }
}
