

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
        return preg_match($other, this._getBodyAsString()) > 0;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return 'PCRE pattern found in response body';
    }

    /**
     * @param mixed $other Expected
     * @return string
     */
    function failureDescription($other): string
    {
        return '`' . $other . '`' . ' ' . this.toString();
    }
}