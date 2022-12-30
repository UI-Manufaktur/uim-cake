

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
module uim.cake.consoles.TestSuite\Constraint;

/**
 * ContentsRegExp
 *
 * @internal
 */
class ContentsRegExp : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return preg_match($other, this.contents) > 0;
    }

    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("PCRE pattern found in %s", this.output);
    }

    /**
     * @param mixed $other Expected
     * @return string
     */
    string failureDescription($other)
    {
        return "`" . $other . "` " . this.toString();
    }
}
