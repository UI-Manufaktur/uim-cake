/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

use Psr\Http\messages.IResponse;

/**
 * BodyContains
 *
 * @internal
 */
class BodyContains : ResponseBase
{
    /**
     */
    protected bool $ignoreCase;

    /**
     * Constructor.
     *
     * @param \Psr\Http\messages.IResponse $response A response instance.
     * @param bool $ignoreCase Ignore case
     */
    this(IResponse $response, bool $ignoreCase = false) {
        super(($response);

        this.ignoreCase = $ignoreCase;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     */
    bool matches($other) {
        $method = "mb_strpos";
        if (this.ignoreCase) {
            $method = "mb_stripos";
        }

        return $method(_getBodyAsString(), $other) != false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return "is in response body";
    }
}
