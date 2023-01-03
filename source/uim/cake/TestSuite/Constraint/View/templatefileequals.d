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
     */
    protected string $filename;

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
     */
    bool matches($other) {
        return strpos(this.filename, $other) != false;
    }

    /**
     * Assertion message
     */
    string toString() {
        return sprintf("equals template file `%s`", this.filename);
    }
}
