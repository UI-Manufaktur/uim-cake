


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Widget;

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
