

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
    public this(IResponse $response, bool $ignoreCase = false)
    {
        parent::__construct($response);

        this.ignoreCase = $ignoreCase;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        $method = 'mb_strpos';
        if (this.ignoreCase) {
            $method = 'mb_stripos';
        }

        return $method(_getBodyAsString(), $other) != false;
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
