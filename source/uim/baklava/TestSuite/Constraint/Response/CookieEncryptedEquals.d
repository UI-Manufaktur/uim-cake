

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.7.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite\Constraint\Response;

import uim.baklava.https\Response;
import uim.baklava.utilities.CookieCryptTrait;

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
    protected myKey;

    /**
     * @var string
     */
    protected myMode;

    /**
     * Constructor.
     *
     * @param \Cake\Http\Response|null $response A response instance.
     * @param string $cookieName Cookie name
     * @param string myMode Mode
     * @param string myKey Key
     */
    this(?Response $response, string $cookieName, string myMode, string myKey) {
        super.this($response, $cookieName);

        this.key = myKey;
        this.mode = myMode;
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

        return $cookie !== null && this._decrypt($cookie['value'], this.mode) === $other;
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
    protected auto _getCookieEncryptionKey(): string
    {
        return this.key;
    }
}
