module uim.cake.views\Widget;

import uim.cake.views\Form\IContext;
import uim.cake.views\Helper\IdGeneratorTrait;
import uim.cake.views\StringTemplate;

/**
 * Input widget class for generating multiple checkboxes.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone multiple checkboxes.
 */
class MultiCheckboxWidget : BasicWidget
{
    use IdGeneratorTrait;

    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "escape": true,
        "options": [],
        "disabled": null,
        "val": null,
        "idPrefix": null,
        "templateVars": [],
        "label": true,
    ];

    /**
     * Label widget instance.
     *
     * @var uim.cake.views\Widget\LabelWidget
     */
    protected _label;

    /**
     * Render multi-checkbox widget.
     *
     * This class uses the following templates:
     *
     * - `checkbox` Renders checkbox input controls. Accepts
     *   the `name`, `value` and `attrs` variables.
     * - `checkboxWrapper` Renders the containing div/element for
     *   a checkbox and its label. Accepts the `input`, and `label`
     *   variables.
     * - `multicheckboxWrapper` Renders a wrapper around grouped inputs.
     * - `multicheckboxTitle` Renders the title element for grouped inputs.
     *
     * @param uim.cake.views\StringTemplate $templates Templates list.
     * @param uim.cake.views\Widget\LabelWidget $label Label widget instance.
     */
    this(StringTemplate $templates, LabelWidget $label) {
        _templates = $templates;
        _label = $label;
    }

    /**
     * Render multi-checkbox widget.
     *
     * Data supports the following options.
     *
     * - `name` The name attribute of the inputs to create.
     *   `[]` will be appended to the name.
     * - `options` An array of options to create checkboxes out of.
     * - `val` Either a string/integer or array of values that should be
     *   checked. Can also be a complex options set.
     * - `disabled` Either a boolean or an array of checkboxes to disable.
     * - `escape` Set to false to disable HTML escaping.
     * - `options` An associative array of value=>labels to generate options for.
     * - `idPrefix` Prefix for generated ID attributes.
     *
     * ### Options format
     *
     * The options option can take a variety of data format depending on
     * the complexity of HTML you want generated.
     *
     * You can generate simple options using a basic associative array:
     *
     * ```
     * "options": ["elk": "Elk", "beaver": "Beaver"]
     * ```
     *
     * If you need to define additional attributes on your option elements
     * you can use the complex form for options:
     *
     * ```
     * "options": [
     *   ["value": "elk", "text": "Elk", "data-foo": "bar"],
     * ]
     * ```
     *
     * This form **requires** that both the `value` and `text` keys be defined.
     * If either is not set options will not be generated correctly.
     *
     * @param array<string, mixed> $data The data to generate a checkbox set with.
     * @param uim.cake.views\Form\IContext $context The current form context.
     */
    string render(array $data, IContext $context) {
        $data += this.mergeDefaults($data, $context);

        _idPrefix = $data["idPrefix"];
        _clearIds();

        return implode("", _renderInputs($data, $context));
    }

    /**
     * Render the checkbox inputs.
     *
     * @param array<string, mixed> $data The data array defining the checkboxes.
     * @param uim.cake.views\Form\IContext $context The current form context.
     * @return array<string> An array of rendered inputs.
     */
    protected string[] _renderInputs(array $data, IContext $context) {
        $out = null;
        foreach ($data["options"] as $key: $val) {
            // Grouped inputs in a fieldset.
            if (is_string($key) && is_array($val) && !isset($val["text"], $val["value"])) {
                $inputs = _renderInputs(["options": $val] + $data, $context);
                $title = _templates.format("multicheckboxTitle", ["text": $key]);
                $out[] = _templates.format("multicheckboxWrapper", [
                    "content": $title . implode("", $inputs),
                ]);
                continue;
            }

            // Standard inputs.
            $checkbox = [
                "value": $key,
                "text": $val,
            ];
            if (is_array($val) && isset($val["text"], $val["value"])) {
                $checkbox = $val;
            }
            if (!isset($checkbox["templateVars"])) {
                $checkbox["templateVars"] = $data["templateVars"];
            }
            if (!isset($checkbox["label"])) {
                $checkbox["label"] = $data["label"];
            }
            if (!empty($data["templateVars"])) {
                $checkbox["templateVars"] = array_merge($data["templateVars"], $checkbox["templateVars"]);
            }
            $checkbox["name"] = $data["name"];
            $checkbox["escape"] = $data["escape"];
            $checkbox["checked"] = _isSelected((string)$checkbox["value"], $data["val"]);
            $checkbox["disabled"] = _isDisabled((string)$checkbox["value"], $data["disabled"]);
            if (empty($checkbox["id"])) {
                if (isset($data["id"])) {
                    $checkbox["id"] = $data["id"] ~ "-" ~ trim(
                        _idSuffix((string)$checkbox["value"]),
                        "-"
                    );
                } else {
                    $checkbox["id"] = _id($checkbox["name"], (string)$checkbox["value"]);
                }
            }
            $out[] = _renderInput($checkbox + $data, $context);
        }

        return $out;
    }

    /**
     * Render a single checkbox & wrapper.
     *
     * @param array<string, mixed> $checkbox An array containing checkbox key/value option pairs
     * @param uim.cake.views\Form\IContext $context Context object.
     */
    protected string _renderInput(array $checkbox, IContext $context) {
        $input = _templates.format("checkbox", [
            "name": $checkbox["name"] ~ "[]",
            "value": $checkbox["escape"] ? h($checkbox["value"]) : $checkbox["value"],
            "templateVars": $checkbox["templateVars"],
            "attrs": _templates.formatAttributes(
                $checkbox,
                ["name", "value", "text", "options", "label", "val", "type"]
            ),
        ]);

        if ($checkbox["label"] == false && strpos(_templates.get("checkboxWrapper"), "{{input}}") == false) {
            $label = $input;
        } else {
            $labelAttrs = is_array($checkbox["label"]) ? $checkbox["label"] : [];
            $labelAttrs += [
                "for": $checkbox["id"],
                "escape": $checkbox["escape"],
                "text": $checkbox["text"],
                "templateVars": $checkbox["templateVars"],
                "input": $input,
            ];

            if ($checkbox["checked"]) {
                $selectedClass = _templates.format("selectedClass", []);
                $labelAttrs = (array)_templates.addClass($labelAttrs, $selectedClass);
            }

            $label = _label.render($labelAttrs, $context);
        }

        return _templates.format("checkboxWrapper", [
            "templateVars": $checkbox["templateVars"],
            "label": $label,
            "input": $input,
        ]);
    }

    /**
     * Helper method for deciding what options are selected.
     *
     * @param string aKey The key to test.
     * @param array<string>|string|int|false|null $selected The selected values.
     */
    protected bool _isSelected(string aKey, $selected) {
        if ($selected == null) {
            return false;
        }
        if (!is_array($selected)) {
            return $key == (string)$selected;
        }
        $strict = !is_numeric($key);

        return hasAllValues($key, $selected, $strict);
    }

    /**
     * Helper method for deciding what options are disabled.
     *
     * @param string aKey The key to test.
     * @param mixed $disabled The disabled values.
     */
    protected bool _isDisabled(string aKey, $disabled) {
        if ($disabled == null || $disabled == false) {
            return false;
        }
        if ($disabled == true || is_string($disabled)) {
            return true;
        }
        $strict = !is_numeric($key);

        return hasAllValues($key, $disabled, $strict);
    }
}
