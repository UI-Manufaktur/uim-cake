module uim.cake.View\Widget;

import uim.cake.View\Form\IContext;
import uim.cake.View\Helper\IdGeneratorTrait;
import uim.cake.View\StringTemplate;
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
        "name": "",
        "options": [],
        "disabled": null,
        "val": null,
        "escape": true,
        "label": true,
        "empty": false,
        "idPrefix": null,
        "templateVars": [],
    ];

    /**
     * Label instance.
     *
     * @var uim.cake.View\Widget\LabelWidget
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
     * @param uim.cake.View\StringTemplate $templates Templates list.
     * @param uim.cake.View\Widget\LabelWidget $label Label widget instance.
     */
    this(StringTemplate $templates, LabelWidget $label) {
        _templates = $templates;
        _label = $label;
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
     * @param array<string, mixed> $data The data to build radio buttons with.
     * @param uim.cake.View\Form\IContext $context The current form context.
     */
    string render(array $data, IContext $context): string
    {
        $data += this.mergeDefaults($data, $context);

        if ($data["options"] instanceof Traversable) {
            $options = iterator_to_array($data["options"]);
        } else {
            $options = (array)$data["options"];
        }

        if (!empty($data["empty"])) {
            $empty = $data["empty"] == true ? "empty" : $data["empty"];
            $options = ["": $empty] + $options;
        }
        unset($data["empty"]);

        _idPrefix = $data["idPrefix"];
        _clearIds();
        $opts = [];
        foreach ($options as $val: $text) {
            $opts[] = _renderInput($val, $text, $data, $context);
        }

        return implode("", $opts);
    }

    /**
     * Disabled attribute detection.
     *
     * @param array<string, mixed> $radio Radio info.
     * @param array|true|null $disabled The disabled values.
     */
    protected bool _isDisabled(array $radio, $disabled) {
        if (!$disabled) {
            return false;
        }
        if ($disabled == true) {
            return true;
        }
        $isNumeric = is_numeric($radio["value"]);

        return !is_array($disabled) || in_array((string)$radio["value"], $disabled, !$isNumeric);
    }

    /**
     * Renders a single radio input and label.
     *
     * @param string|int $val The value of the radio input.
     * @param array<string, mixed>|string $text The label text, or complex radio type.
     * @param array<string, mixed> $data Additional options for input generation.
     * @param uim.cake.View\Form\IContext $context The form context
     */
    protected string _renderInput($val, $text, $data, $context): string
    {
        $escape = $data["escape"];
        if (is_array($text) && isset($text["text"], $text["value"])) {
            $radio = $text;
        } else {
            $radio = ["value": $val, "text": $text];
        }
        $radio["name"] = $data["name"];

        $radio["templateVars"] = $radio["templateVars"] ?? [];
        if (!empty($data["templateVars"])) {
            $radio["templateVars"] = array_merge($data["templateVars"], $radio["templateVars"]);
        }

        if (empty($radio["id"])) {
            if (isset($data["id"])) {
                $radio["id"] = $data["id"] ~ "-" ~ rtrim(
                    _idSuffix((string)$radio["value"]),
                    "-"
                );
            } else {
                $radio["id"] = _id((string)$radio["name"], (string)$radio["value"]);
            }
        }
        if (isset($data["val"]) && is_bool($data["val"])) {
            $data["val"] = $data["val"] ? 1 : 0;
        }
        if (isset($data["val"]) && (string)$data["val"] == (string)$radio["value"]) {
            $radio["checked"] = true;
            $radio["templateVars"]["activeClass"] = "active";
        }

        if (!is_bool($data["label"]) && isset($radio["checked"]) && $radio["checked"]) {
            $selectedClass = _templates.format("selectedClass", []);
            $data["label"] = _templates.addClass($data["label"], $selectedClass);
        }

        $radio["disabled"] = _isDisabled($radio, $data["disabled"]);
        if (!empty($data["required"])) {
            $radio["required"] = true;
        }
        if (!empty($data["form"])) {
            $radio["form"] = $data["form"];
        }

        $input = _templates.format("radio", [
            "name": $radio["name"],
            "value": $escape ? h($radio["value"]) : $radio["value"],
            "templateVars": $radio["templateVars"],
            "attrs": _templates.formatAttributes(
                $radio + $data,
                ["name", "value", "text", "options", "label", "val", "type"]
            ),
        ]);

        $label = _renderLabel(
            $radio,
            $data["label"],
            $input,
            $context,
            $escape
        );

        if (
            $label == false &&
            strpos(_templates.get("radioWrapper"), "{{input}}") == false
        ) {
            $label = $input;
        }

        return _templates.format("radioWrapper", [
            "input": $input,
            "label": $label,
            "templateVars": $data["templateVars"],
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
     * @param uim.cake.View\Form\IContext $context The form context.
     * @param bool $escape Whether to HTML escape the label.
     * @return string|false Generated label.
     */
    protected function _renderLabel(array $radio, $label, $input, $context, $escape) {
        if (isset($radio["label"])) {
            $label = $radio["label"];
        } elseif ($label == false) {
            return false;
        }
        $labelAttrs = is_array($label) ? $label : [];
        $labelAttrs += [
            "for": $radio["id"],
            "escape": $escape,
            "text": $radio["text"],
            "templateVars": $radio["templateVars"],
            "input": $input,
        ];

        return _label.render($labelAttrs, $context);
    }
}
