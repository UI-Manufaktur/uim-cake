module uim.cake.View\Widget;

import uim.cake.View\Form\IContext;
import uim.cake.View\StringTemplate;
use IDateTime;
use InvalidArgumentException;

/**
 * Input widget class for generating a calendar year select box.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone calendar year select boxes.
 */
class YearWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        'name' => '',
        'val' => null,
        'min' => null,
        'max' => null,
        'order' => 'desc',
        'templateVars' => [],
    ];

    /**
     * Select box widget.
     *
     * @var \Cake\View\Widget\SelectBoxWidget
     */
    protected $_select;

    /**
     * Constructor
     *
     * @param \Cake\View\StringTemplate myTemplates Templates list.
     * @param \Cake\View\Widget\SelectBoxWidget $selectBox Selectbox widget instance.
     */
    this(StringTemplate myTemplates, SelectBoxWidget $selectBox)
    {
        this._select = $selectBox;
        this._templates = myTemplates;
    }

    /**
     * Renders a year select box.
     *
     * @param array<string, mixed> myData Data to render with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string A generated select box.
     */
    function render(array myData, IContext $context): string
    {
        myData += this.mergeDefaults(myData, $context);

        if (empty(myData['min'])) {
            myData['min'] = date('Y', strtotime('-5 years'));
        }

        if (empty(myData['max'])) {
            myData['max'] = date('Y', strtotime('+5 years'));
        }

        myData['min'] = (int)myData['min'];
        myData['max'] = (int)myData['max'];

        if (myData['val'] instanceof IDateTime) {
            myData['val'] = myData['val'].format('Y');
        }

        if (!empty(myData['val'])) {
            myData['min'] = min((int)myData['val'], myData['min']);
            myData['max'] = max((int)myData['val'], myData['max']);
        }

        if (myData['max'] < myData['min']) {
            throw new InvalidArgumentException('Max year cannot be less than min year');
        }

        if (myData['order'] === 'desc') {
            myData['options'] = range(myData['max'], myData['min']);
        } else {
            myData['options'] = range(myData['min'], myData['max']);
        }
        myData['options'] = array_combine(myData['options'], myData['options']);

        unset(myData['order'], myData['min'], myData['max']);

        return this._select.render(myData, $context);
    }
}
