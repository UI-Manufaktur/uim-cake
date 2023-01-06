/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * BodyEquals
 *
 * @internal
 */
class BodyEquals : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        return _getBodyAsString() == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "matches response body";
    }
}
