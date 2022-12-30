

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *

 * @since         3.7.0

 */
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
     * @var bool
     */
    protected $ignoreCase;

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
     * @return bool
     */
    function matches($other): bool
    {
        $method = "mb_strpos";
        if (this.ignoreCase) {
            $method = "mb_stripos";
        }

        return $method(_getBodyAsString(), $other) != false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    string toString()
    {
        return "is in response body";
    }
}
