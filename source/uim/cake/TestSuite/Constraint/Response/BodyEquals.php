

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
 * BodyEquals
 *
 * @internal
 */
class BodyEquals : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected type
     * @return bool
     */
    function matches($other): bool
    {
        return _getBodyAsString() == $other;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return "matches response body";
    }
}
