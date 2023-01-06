/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyEmpty
 *
 * @internal
 */
class BodyEmpty : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        return empty(_getBodyAsString());
    }

    /**
     * Assertion message
     */
    string toString() {
        return "response body is empty";
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     */
    protected string failureDescription($other) {
        return this.toString();
    }
}
