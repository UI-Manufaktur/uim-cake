/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Email;

import uim.cake.mailers.Message;

/**
 * MailContainsText
 *
 * @internal
 */
class MailContainsText : MailContains
{

    protected $type = Message::MESSAGE_TEXT;

    /**
     * Assertion message string
     */
    string toString() {
        if (this.at) {
            return sprintf("is in the text message of email #%d", this.at) . this.getAssertedMessages();
        }

        return "is in the text message of an email" ~ this.getAssertedMessages();
    }
}
