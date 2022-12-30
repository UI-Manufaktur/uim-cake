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
