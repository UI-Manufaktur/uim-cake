module uim.baklava.views\Widget;

import uim.baklava.views\Form\IContext;
import uim.baklava.views\Helper\IdGeneratorTrait;
import uim.baklava.views\StringTemplate;
use Traversable;

/**
 * Input widget class for generating a set of radio buttons.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone radio buttons.
 */
class RadioWidget : BasicWidget
{
    use IdGeneratorTrait;

    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        'name' => '',
        'options' => [],
        'disabled' => null,
        'val' => null,
        'escape' => true,
        'label' => true,
        'empty' => false,
        'idPrefix' => null,
        'templateVars' => [],
    ];

    /**
     * Label instance.
     *
     * @var \Cake\View\Widget\LabelWidget
     */
    protected $_label;

    /**
     * Constructor
     *
     * This class uses a few templates:
     *
     * - `radio` Used to generate the input for a radio button.
     *   Can use the following variables `name`, `value`, `attrs`.
     * - `radioWrapper` Used to generate the container element for
     *   the radio + input element. Can use the `input` and `label`
     *   variables.
     *
     * @param \Cake\View\StringTemplate myTemplates Templates list.
     * @param \Cake\View\Widget\LabelWidget $label Label widget instance.
     */
    this(StringTemplate myTemplates, LabelWidget $label) {
        this._templates = myTemplates;
        this._label = $label;
    }

    /**
     * Render a set of radio buttons.
     *
     * Data supports the following keys:
     *
     * - `name` - Set the input name.
     * - `options` - An array of options. See below for more information.
     * - `disabled` - Either true or an array of inputs to disable.
     *    When true, the select element will be disabled.
     * - `val` - A string of the option to mark as selected.
     * - `label` - Either false to disable label generation, or
     *   an array of attributes for all labels.
     * - `required` - Set to true to add the required attribute
     *   on all generated radios.
     * - `idPrefix` Prefix for generated ID attributes.
     *
     * @param array<string, mixed> myData The data to build radio buttons with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string
     */
    function render(array myData, IContext $context): string
    {
        myData += this.mergeDefaults(myData, $context);

        if (myData['options'] instanceof Traversable) {
            myOptions = iterator_to_array(myData['options']);
        } else {
            myOptions = (array)myData['options'];
        }

        if (!empty(myData['empty'])) {
            $empty = myData['empty'] === true ? 'empty' : myData['empty'];
            myOptions = ['' => $empty] + myOptions;
        }
        unset(myData['empty']);

        this._idPrefix = myData['idPrefix'];
        this._clearIds();
        $opts = [];
        foreach (myOptions as $val => $text) {
            $opts[] = this._renderInput($val, $text, myData, $context);
        }

        return implode('', $opts);
    }

    /**
     * Disabled attribute detection.
     *
     * @param array<string, mixed> $radio Radio info.
     * @param array|true|null $disabled The disabled values.
     * @return bool
     */
    protected auto _isDisabled(array $radio, $disabled): bool
    {
        if (!$disabled) {
            return false;
        }
        if ($disabled === true) {
            return true;
        }
        $isNumeric = is_numeric($radio['value']);

        return !is_array($disabled) || in_array((string)$radio['value'], $disabled, !$isNumeric);
    }

    /**
     * Renders a single radio input and label.
     *
     * @param string|int $val The value of the radio input.
     * @param array<string, mixed>|string $text The label text, or complex radio type.
     * @param array<string, mixed> myData Additional options for input generation.
     * @param \Cake\View\Form\IContext $context The form context
     * @return string
     */
    protected auto _renderInput($val, $text, myData, $context): string
    {
        $escape = myData['escape'];
        if (is_array($text) && isset($text['text'], $text['value'])) {
            $radio = $text;
        } else {
            $radio = ['value' => $val, 'text' => $text];
        }
        $radio['name'] = myData['name'];

        $radio['templateVars'] = $radio['templateVars'] ?? [];
        if (!empty(myData['templateVars'])) {
            $radio['templateVars'] = array_merge(myData['templateVars'], $radio['templateVars']);
        }

        if (empty($radio['id'])) {
            if (isset(myData['id'])) {
                $radio['id'] = myData['id'] . '-' . rtrim(
                    this._idSuffix((string)$radio['value']),
                    '-'
                );
            } else {
                $radio['id'] = this._id((string)$radio['name'], (string)$radio['value']);
            }
        }
        if (isset(myData['val']) && is_bool(myData['val'])) {
            myData['val'] = myData['val'] ? 1 : 0;
        }
        if (isset(myData['val']) && (string)myData['val'] === (string)$radio['value']) {
            $radio['checked'] = true;
            $radio['templateVars']['activeClass'] = 'active';
        }

        if (!is_bool(myData['label']) && isset($radio['checked']) && $radio['checked']) {
            $selectedClass = this._templates.format('selectedClass', []);
            myData['label'] = this._templates.addClass(myData['label'], $selectedClass);
        }

        $radio['disabled'] = this._isDisabled($radio, myData['disabled']);
        if (!empty(myData['required'])) {
            $radio['required'] = true;
        }
        if (!empty(myData['form'])) {
            $radio['form'] = myData['form'];
        }

        $input = this._templates.format('radio', [
            'name' => $radio['name'],
            'value' => $escape ? h($radio['value']) : $radio['value'],
            'templateVars' => $radio['templateVars'],
            'attrs' => this._templates.formatAttributes(
                $radio + myData,
                ['name', 'value', 'text', 'options', 'label', 'val', 'type']
            ),
        ]);

        $label = this._renderLabel(
            $radio,
            myData['label'],
            $input,
            $context,
            $escape
        );

        if (
            $label === false &&
            strpos(this._templates.get('radioWrapper'), '{{input}}') === false
        ) {
            $label = $input;
        }

        return this._templates.format('radioWrapper', [
            'input' => $input,
            'label' => $label,
            'templateVars' => myData['templateVars'],
        ]);
    }

    /**
     * Renders a label element for a given radio button.
     *
     * In the future this might be refactored into a separate widget as other
     * input types (multi-checkboxes) will also need labels generated.
     *
     * @param array<string, mixed> $radio The input properties.
     * @param array<string, mixed>|string|false $label The properties for a label.
     * @param string $input The input widget.
     * @param \Cake\View\Form\IContext $context The form context.
     * @param bool $escape Whether to HTML escape the label.
     * @return string|false Generated label.
     */
    protected auto _renderLabel(array $radio, $label, $input, $context, $escape) {
        if (isset($radio['label'])) {
            $label = $radio['label'];
        } elseif ($label === false) {
            return false;
        }
        $labelAttrs = is_array($label) ? $label : [];
        $labelAttrs += [
            'for' => $radio['id'],
            'escape' => $escape,
            'text' => $radio['text'],
            'templateVars' => $radio['templateVars'],
            'input' => $input,
        ];

        return this._label.render($labelAttrs, $context);
    }
}
