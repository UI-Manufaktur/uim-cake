

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

/**
 * StatusFailure
 *
 * @internal
 */
class StatusFailure : StatusCodeBase
{
    /**
     * @var array<int, int>|int
     */
    protected $code = [500, 505];

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('%d is between 500 and 505', this.response.getStatusCode());
    }
}