

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.7.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\Response;

import uim.cake.Http\Response;
import uim.cake.Utility\CookieCryptTrait;

/**
 * CookieEncryptedEquals
 *
 * @internal
 */
class CookieEncryptedEquals : CookieEquals
{
    use CookieCryptTrait;

    /**
     * @var \Cake\Http\Response
     */
    protected $response;

    /**
     * @var string
     */
    protected $key;

    /**
     * @var string
     */
    protected $mode;

    /**
     * Constructor.
     *
     * @param \Cake\Http\Response|null $response A response instance.
     * @param string $cookieName Cookie name
     * @param string $mode Mode
     * @param string $key Key
     */
    public this(?Response $response, string $cookieName, string $mode, string $key)
    {
        super(($response, $cookieName);

        this.key = $key;
        this.mode = $mode;
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

        return $cookie != null && _decrypt($cookie['value'], this.mode) == $other;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('is encrypted in cookie \'%s\'', this.cookieName);
    }

    /**
     * Returns the encryption key
     *
     * @return string
     */
    protected function _getCookieEncryptionKey(): string
    {
        return this.key;
    }
}
