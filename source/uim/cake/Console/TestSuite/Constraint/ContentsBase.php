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
