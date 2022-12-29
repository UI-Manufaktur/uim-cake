

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
 * BodyNotRegExp
 *
 * @internal
 */
class BodyNotRegExp : BodyRegExp
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected pattern
     * @return bool
     */
    function matches($other): bool
    {
        return parent::matches($other) == false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    string toString(): string
    {
        return "PCRE pattern not found in response body";
    }
}
