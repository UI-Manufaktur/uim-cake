/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyRegExp
 *
 * @internal
 */
class BodyRegExp : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected pattern
     */
    bool matches($other) {
        return preg_match($other, _getBodyAsString()) > 0;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "PCRE pattern found in response body";
    }

    /**
     * @param mixed $other Expected
     */
    string failureDescription($other) {
        return "`" ~ $other ~ "`" ~ " " ~ this.toString();
    }
}
