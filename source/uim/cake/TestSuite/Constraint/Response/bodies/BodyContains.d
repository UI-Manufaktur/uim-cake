

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
 */module uim.cake.TestSuite\Constraint\Response;

use Psr\Http\Message\IResponse;

/**
 * BodyContains
 *
 * @internal
 */
class BodyContains : ResponseBase
{
    /**
     * @var bool
     */
    protected $ignoreCase;

    /**
     * Constructor.
     *
     * @param \Psr\Http\Message\IResponse $response A response instance.
     * @param bool $ignoreCase Ignore case
     */
    this(IResponse $response, bool $ignoreCase = false) {
        super.this($response);

        this.ignoreCase = $ignoreCase;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    bool matches($other) {
        $method = 'mb_strpos';
        if (this.ignoreCase) {
            $method = 'mb_stripos';
        }

        return $method(this._getBodyAsString(), $other) !== false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'is in response body';
    }
}
