

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.7.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.TestSuite\Constraint\View;

use PHPUnit\Framework\Constraint\Constraint;

/**
 * TemplateFileEquals
 *
 * @internal
 */
class TemplateFileEquals : Constraint
{
    /**
     * @var string
     */
    protected $filename;

    /**
     * Constructor
     *
     * @param string $filename Template file name
     */
    public this(string $filename) {
        this.filename = $filename;
    }

    /**
     * Checks assertion
     *
     * @param mixed $other Expected filename
     * @return bool
     */
    function matches($other): bool
    {
        return strpos(this.filename, $other) != false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf("equals template file `%s`", this.filename);
    }
}
