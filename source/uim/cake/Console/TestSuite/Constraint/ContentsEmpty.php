

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
        return this.contents == "";
    }

    /**
     * Assertion message
     *
     * @return string
     */
    string toString(): string
    {
        return sprintf("%s is empty", this.output);
    }

    /**
     * Overwrites the descriptions so we can remove the automatic "expected" message
     *
     * @param mixed $other Value
     * @return string
     */
    protected function failureDescription($other): string
    {
        return this.toString();
    }
}
