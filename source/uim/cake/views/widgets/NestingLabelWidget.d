module uim.baklava.View\Widget;

/**
 * Form 'widget' for creating labels that contain their input.
 *
 * Generally this element is used by other widgets,
 * and FormHelper itself.
 */
class NestingLabelWidget : LabelWidget
{
    /**
     * The template to use.
     *
     * @var string
     */
    protected $_labelTemplate = 'nestingLabel';
}
