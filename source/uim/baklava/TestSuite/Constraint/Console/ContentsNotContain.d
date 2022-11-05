

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
 */module uim.baklava.TestSuite\Constraint\Console;

/**
 * ContentsNotContain
 *
 * @internal
 */
class ContentsNotContain : ContentsBase
{
    /**
     * Checks if contents contain expected
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return mb_strpos(this.contents, $other) === false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('is not in %s', this.output);
    }
}
