

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
 * HeaderContains
 *
 * @internal
 */
class HeaderContains : HeaderEquals
{
    /**
     * Checks assertion
     *
     * @param mixed $other Expected content
     * @return bool
     */
    bool matches($other) {
        return mb_strpos(this.response.getHeaderLine(this.headerName), $other) !== false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf(
            'is in header \'%s\' (`%s`)',
            this.headerName,
            this.response.getHeaderLine(this.headerName)
        );
    }
}
