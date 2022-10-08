

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

use PHPUnit\Framework\Constraint\Constraint;

/**
 * Base constraint for content constraints
 *
 * @internal
 */
abstract class ContentsBase : Constraint
{
    /**
     * @var string
     */
    protected myContentss;

    /**
     * @var string
     */
    protected $output;

    /**
     * Constructor
     *
     * @param array<string> myContentss Contents
     * @param string $output Output type
     */
    this(array myContentss, string $output) {
        this.contents = implode(PHP_EOL, myContentss);
        this.output = $output;
    }
}
