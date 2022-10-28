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
    this(string $filename) {
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
        return strpos(this.filename, $other) !== false;
    }

    /**
     * Assertion message
     *
     * @return string
     */
    function toString(): string
    {
        return sprintf('equals template file `%s`', this.filename);
    }
}
