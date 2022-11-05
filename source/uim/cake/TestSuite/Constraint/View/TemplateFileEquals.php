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
    protected myfilename;

    /**
     * Constructor
     *
     * @param string myfilename Template file name
     */
    this(string myfilename) {
        this.filename = myfilename;
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
