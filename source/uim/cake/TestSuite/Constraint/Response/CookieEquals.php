

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Response;

import uim.cake.http.Response;

/**
 * CookieEquals
 *
 * @internal
 */
class CookieEquals : ResponseBase
{
    /**
     * @var uim.cake.http.Response
     */
    protected $response;

    /**
     * @var string
     */
    protected $cookieName;

    /**
     * Constructor.
     *
     * @param uim.cake.http.Response|null $response A response instance.
     * @param string $cookieName Cookie name
     */
    public this(?Response $response, string $cookieName) {
        super(($response);

        this.cookieName = $cookieName;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    function matches($other): bool
    {
        $cookie = this.response.getCookie(this.cookieName);

        return $cookie != null && $cookie["value"] == $other;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf("is in cookie \"%s\"", this.cookieName);
    }
}
