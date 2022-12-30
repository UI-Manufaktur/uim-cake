

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

use PHPUnit\Framework\Constraint\Constraint;

/**
 * Base constraint for content constraints
 *
 * @internal
 */
abstract class ContentsBase : Constraint
{
    /**
     */
    protected string $contents;

    /**
     */
    protected string $output;

    /**
     * Constructor
     *
     * @param array<string> $contents Contents
     * @param string $output Output type
     */
    this(array $contents, string $output) {
        this.contents = implode(PHP_EOL, $contents);
        this.output = $output;
    }
}
