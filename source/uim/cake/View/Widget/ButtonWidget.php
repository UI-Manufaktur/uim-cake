


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;
import uim.cake.View\StringTemplate;

/**
 * Button input class
 *
 * This input class can be used to render button elements.
 * If you need to make basic submit inputs with type=submit,
 * use the Basic input widget.
 */
class ButtonWidget : WidgetInterface
{
    /**
     * StringTemplate instance.
     *
     * @var \Cake\View\StringTemplate
     */
    protected $_templates;

    /**
     * Constructor.
     *
     * @param \Cake\View\StringTemplate $templates Templates list.
     */
    public this(StringTemplate $templates)
    {
        _templates = $templates;
    }

    /**
     * Render a button.
     *
     * This method accepts a number of keys:
     *
     * - `text` The text of the button. Unlike all other form controls, buttons
     *   do not escape their contents by default.
     * - `escapeTitle` Set to false to disable escaping of button text.
     * - `escape` Set to false to disable escaping of attributes.
     * - `type` The button type defaults to 'submit'.
     *
     * Any other keys provided in $data will be converted into HTML attributes.
     *
     * @param array<string, mixed> $data The data to build a button with.
     * @param \Cake\View\Form\ContextInterface $context The current form context.
     * @return string
     */
    function render(array $data, ContextInterface $context): string
    {
        $data += [
            'text': '',
            'type': 'submit',
            'escapeTitle': true,
            'escape': true,
            'templateVars': [],
        ];

        return _templates.format('button', [
            'text': $data['escapeTitle'] ? h($data['text']) : $data['text'],
            'templateVars': $data['templateVars'],
            'attrs': _templates.formatAttributes($data, ['text', 'escapeTitle']),
        ]);
    }

    /**
     * @inheritDoc
     */
    function secureFields(array $data): array
    {
        if (!isset($data['name']) || $data['name'] == '') {
            return [];
        }

        return [$data['name']];
    }
}
