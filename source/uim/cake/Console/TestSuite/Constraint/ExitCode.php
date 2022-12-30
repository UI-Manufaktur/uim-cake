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
