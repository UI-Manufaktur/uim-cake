/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.TestSuite\Constraint\Response;

import uim.cake.http.Response;
import uim.cake.utilities.CookieCryptTrait;

/**
 * CookieEncryptedEquals
 *
 * @internal
 */
class CookieEncryptedEquals : CookieEquals
{
    use CookieCryptTrait;

    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     */
    protected string aKey;

    /**
     */
    protected string $mode;

    /**
     * Constructor.
     *
     * @param uim.cake.http.Response|null $response A response instance.
     * @param string $cookieName Cookie name
     * @param string $mode Mode
     * @param string aKey Key
     */
    this(?Response $response, string $cookieName, string $mode, string aKey) {
        super(($response, $cookieName);

        this.key = $key;
        this.mode = $mode;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     */
    bool matches($other) {
        $cookie = this.response.getCookie(this.cookieName);

        return $cookie != null && _decrypt($cookie["value"], this.mode) == $other;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("is encrypted in cookie \"%s\"", this.cookieName);
    }

    /**
     * Returns the encryption key
     */
    protected string _getCookieEncryptionKey() {
        return this.key;
    }
}
