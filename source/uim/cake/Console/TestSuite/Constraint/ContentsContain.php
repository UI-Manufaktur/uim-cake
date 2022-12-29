

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
 * ContentsContain
 *
 * @internal
 */
class ContentsContain : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return mb_strpos(this.contents, $other) != false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    string toString(): string
    {
        return sprintf("is in %s," . PHP_EOL . "actual result:" . PHP_EOL, this.output) . this.contents;
    }
}
