

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
 */module uim.cake.TestSuite\Constraint\Console;

/**
 * ContentsEmpty
 *
 * @internal
 */
class ContentsEmpty : ContentsBase
{
    /**
     * Checks if contents are empty
     *
     * @param mixed $other Expected
     * @return bool
     */
    function matches($other): bool
    {
        return this.contents === '';
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('%s is empty', this.output);
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected auto failureDescription($other): string
    {
        return this.toString();
    }
}
