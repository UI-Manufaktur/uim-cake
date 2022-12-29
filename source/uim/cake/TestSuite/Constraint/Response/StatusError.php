

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

/**
 * StatusError
 *
 * @internal
 */
class StatusError : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [400, 429];

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf("%d is between 400 and 429", this.response.getStatusCode());
    }
}
