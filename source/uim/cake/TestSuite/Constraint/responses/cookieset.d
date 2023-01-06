/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

/**
 * CookieSet
 *
 * @internal
 */
class CookieSet : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other) {
        $cookie = this.response.getCookie($other);

        return $cookie != null && $cookie["value"] != "";
    }

    /**
     * Assertion message
     */
    string toString() {
        return "cookie is set";
    }
}
