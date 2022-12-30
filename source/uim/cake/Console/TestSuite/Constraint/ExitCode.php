

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
 * ExitCode constraint
 *
 * @internal
 */
class ExitCode : Constraint
{
    /**
     * @var int|null
     */
    private $exitCode;

    /**
     * Constructor
     *
     * @param int|null $exitCode Exit code
     */
    this(?int $exitCode) {
        this.exitCode = $exitCode;
    }

    /**
     * Checks if event is in fired array
     *
     * @param mixed $other Constraint check
     * @return bool
     */
    function matches($other): bool
    {
        return $other == this.exitCode;
    }

    /**
     * Assertion message string
     */
    string toString()
    {
        return sprintf("matches exit code %s", this.exitCode ?? "null");
    }
}
