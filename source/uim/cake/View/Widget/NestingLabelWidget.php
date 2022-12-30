
module uim.cake.View\Widget;

/**
 * Form "widget" for creating labels that contain their input.
 *
 * Generally this element is used by other widgets,
 * and FormHelper itself.
 */
class NestingLabelWidget : LabelWidget
{
    /**
     * The template to use.
     *
     */
    protected string $_labelTemplate = "nestingLabel";
}
