

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
 * StatusSuccess
 *
 * @internal
 */
class StatusSuccess : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [200, 308];

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("%d is between 200 and 308", this.response.getStatusCode());
    }
}
