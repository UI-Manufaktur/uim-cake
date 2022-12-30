

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
module uim.cake.TestSuite\Constraint\View;

/**
 * LayoutFileEquals
 *
 * @internal
 */
class LayoutFileEquals : TemplateFileEquals
{
    /**
     * Assertion message
     */
    string toString()
    {
        return sprintf("equals layout file `%s`", this.filename);
    }
}
