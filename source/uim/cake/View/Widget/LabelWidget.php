module uim.cake.View\Widget;

import uim.cake.View\Form\IContext;
import uim.cake.View\StringTemplate;

/**
 * Form 'widget' for creating labels.
 *
 * Generally this element is used by other widgets,
 * and FormHelper itself.
 */
class LabelWidget : WidgetInterface
{
    /**
     * Templates
     *
     * @var \Cake\View\StringTemplate
     */
    protected $_templates;

    /**
     * The template to use.
     *
     * @var string
     */
    protected $_labelTemplate = 'label';

    /**
     * Constructor.
     *
     * This class uses the following template:
     *
     * - `label` Used to generate the label for a radio button.
     *   Can use the following variables `attrs`, `text` and `input`.
     *
     * @param \Cake\View\StringTemplate myTemplates Templates list.
     */
    this(StringTemplate myTemplates)
    {
        this._templates = myTemplates;
    }

    /**
     * Render a label widget.
     *
     * Accepts the following keys in myData:
     *
     * - `text` The text for the label.
     * - `input` The input that can be formatted into the label if the template allows it.
     * - `escape` Set to false to disable HTML escaping.
     *
     * All other attributes will be converted into HTML attributes.
     *
     * @param array<string, mixed> myData Data array.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string
     */
    function render(array myData, IContext $context): string
    {
        myData += [
            'text' => '',
            'input' => '',
            'hidden' => '',
            'escape' => true,
            'templateVars' => [],
        ];

        return this._templates.format(this._labelTemplate, [
            'text' => myData['escape'] ? h(myData['text']) : myData['text'],
            'input' => myData['input'],
            'hidden' => myData['hidden'],
            'templateVars' => myData['templateVars'],
            'attrs' => this._templates.formatAttributes(myData, ['text', 'input', 'hidden']),
        ]);
    }

    /**
     * @inheritDoc
     */
    function secureFields(array myData): array
    {
        return [];
    }
}
