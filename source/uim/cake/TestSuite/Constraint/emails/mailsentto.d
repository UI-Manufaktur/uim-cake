/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Email;

/**
 * MailSentTo
 *
 * @internal
 */
class MailSentTo : MailSentWith
{
    /**
     */
    protected string $method = "to";

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("was sent email #%d", this.at);
        }

        return "was sent an email";
    }
}
