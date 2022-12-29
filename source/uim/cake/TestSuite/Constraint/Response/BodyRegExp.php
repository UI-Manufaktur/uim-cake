

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
 * BodyRegExp
 *
 * @internal
 */
class BodyRegExp : ResponseBase
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected pattern
     * @return bool
     */
    function matches($other): bool
    {
        return preg_match($other, _getBodyAsString()) > 0;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return "PCRE pattern found in response body";
    }

    /**
     * @param mixed $other Expected
     * @return string
     */
    function failureDescription($other): string
    {
        return "`" . $other . "`" . " " . this.toString();
    }
}
