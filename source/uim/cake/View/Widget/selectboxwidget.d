module uim.cake.View\Widget;

import uim.cake.View\Form\IContext;
use Traversable;

/**
 * Input widget class for generating a selectbox.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone select boxes.
 */
class SelectBoxWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "empty": false,
        "escape": true,
        "options": [],
        "disabled": null,
        "val": null,
        "templateVars": [],
    ];

    /**
     * Render a select box form input.
     *
     * Render a select box input given a set of data. Supported keys
     * are:
     *
     * - `name` - Set the input name.
     * - `options` - An array of options.
     * - `disabled` - Either true or an array of options to disable.
     *    When true, the select element will be disabled.
     * - `val` - Either a string or an array of options to mark as selected.
     * - `empty` - Set to true to add an empty option at the top of the
     *   option elements. Set to a string to define the display text of the
     *   empty option. If an array is used the key will set the value of the empty
     *   option while, the value will set the display text.
     * - `escape` - Set to false to disable HTML escaping.
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
     * If you need to define option groups you can do those using nested arrays:
     *
     * ```
     * "options": [
     *  "Mammals": [
     *    "elk": "Elk",
     *    "beaver": "Beaver"
     *  ]
     * ]
     * ```
     *
     * And finally, if you need to put attributes on your optgroup elements you
     * can do that with a more complex nested array form:
     *
     * ```
     * "options": [
     *   [
     *     "text": "Mammals",
     *     "data-id": 1,
     *     "options": [
     *       "elk": "Elk",
     *       "beaver": "Beaver"
     *     ]
     *  ],
     * ]
     * ```
     *
     * You are free to mix each of the forms in the same option set, and
     * nest complex types as required.
     *
     * @param array<string, mixed> $data Data to render with.
     * @param uim.cake.View\Form\IContext $context The current form context.
     * @return string A generated select box.
     * @throws \RuntimeException when the name attribute is empty.
     */
    string render(array $data, IContext $context)
    {
        $data += this.mergeDefaults($data, $context);

        $options = _renderContent($data);
        $name = $data["name"];
        unset($data["name"], $data["options"], $data["empty"], $data["val"], $data["escape"]);
        if (isset($data["disabled"]) && is_array($data["disabled"])) {
            unset($data["disabled"]);
        }

        $template = "select";
        if (!empty($data["multiple"])) {
            $template = "selectMultiple";
            unset($data["multiple"]);
        }
        $attrs = _templates.formatAttributes($data);

        return _templates.format($template, [
            "name": $name,
            "templateVars": $data["templateVars"],
            "attrs": $attrs,
            "content": implode("", $options),
        ]);
    }

    /**
     * Render the contents of the select element.
     *
     * @param array<string, mixed> $data The context for rendering a select.
     * @return array<string>
     */
    protected string[] _renderContent(array $data): array
    {
        $options = $data["options"];

        if ($options instanceof Traversable) {
            $options = iterator_to_array($options);
        }

        if (!empty($data["empty"])) {
            $options = _emptyValue($data["empty"]) + (array)$options;
        }
        if (empty($options)) {
            return [];
        }

        $selected = $data["val"] ?? null;
        $disabled = null;
        if (isset($data["disabled"]) && is_array($data["disabled"])) {
            $disabled = $data["disabled"];
        }
        $templateVars = $data["templateVars"];

        return _renderOptions($options, $disabled, $selected, $templateVars, $data["escape"]);
    }

    /**
     * Generate the empty value based on the input.
     *
     * @param array|string|bool $value The provided empty value.
     * @return array The generated option key/value.
     */
    protected function _emptyValue($value): array
    {
        if ($value == true) {
            return ["": ""];
        }
        if (is_scalar($value)) {
            return ["": $value];
        }
        if (is_array($value)) {
            return $value;
        }

        return [];
    }

    /**
     * Render the contents of an optgroup element.
     *
     * @param string $label The optgroup label text
     * @param \ArrayAccess|array $optgroup The opt group data.
     * @param array|null $disabled The options to disable.
     * @param array|string|null $selected The options to select.
     * @param array $templateVars Additional template variables.
     * @param bool $escape Toggle HTML escaping
     * @return string Formatted template string
     */
    protected string _renderOptgroup(
        string $label,
        $optgroup,
        ?array $disabled,
        $selected,
        $templateVars,
        $escape
    ) {
        $opts = $optgroup;
        $attrs = [];
        if (isset($optgroup["options"], $optgroup["text"])) {
            $opts = $optgroup["options"];
            $label = $optgroup["text"];
            $attrs = (array)$optgroup;
        }
        $groupOptions = _renderOptions($opts, $disabled, $selected, $templateVars, $escape);

        return _templates.format("optgroup", [
            "label": $escape ? h($label) : $label,
            "content": implode("", $groupOptions),
            "templateVars": $templateVars,
            "attrs": _templates.formatAttributes($attrs, ["text", "options"]),
        ]);
    }

    /**
     * Render a set of options.
     *
     * Will recursively call itself when option groups are in use.
     *
     * @param iterable $options The options to render.
     * @param array<string>|null $disabled The options to disable.
     * @param array|string|null $selected The options to select.
     * @param array $templateVars Additional template variables.
     * @param bool $escape Toggle HTML escaping.
     * @return array<string> Option elements.
     */
    protected string[] _renderOptions(iterable $options, ?array $disabled, $selected, $templateVars, $escape): array
    {
        $out = [];
        foreach ($options as $key: $val) {
            // Option groups
            $isIterable = is_iterable($val);
            if (
                (
                    !is_int($key) &&
                    $isIterable
                ) ||
                (
                    is_int($key) &&
                    $isIterable &&
                    (
                        isset($val["options"]) ||
                        !isset($val["value"])
                    )
                )
            ) {
                $out[] = _renderOptgroup((string)$key, $val, $disabled, $selected, $templateVars, $escape);
                continue;
            }

            // Basic options
            $optAttrs = [
                "value": $key,
                "text": $val,
                "templateVars": [],
            ];
            if (is_array($val) && isset($val["text"], $val["value"])) {
                $optAttrs = $val;
                $key = $optAttrs["value"];
            }
            $optAttrs["templateVars"] = $optAttrs["templateVars"] ?? [];
            if (_isSelected((string)$key, $selected)) {
                $optAttrs["selected"] = true;
            }
            if (_isDisabled((string)$key, $disabled)) {
                $optAttrs["disabled"] = true;
            }
            if (!empty($templateVars)) {
                $optAttrs["templateVars"] = array_merge($templateVars, $optAttrs["templateVars"]);
            }
            $optAttrs["escape"] = $escape;

            $out[] = _templates.format("option", [
                "value": $escape ? h($optAttrs["value"]) : $optAttrs["value"],
                "text": $escape ? h($optAttrs["text"]) : $optAttrs["text"],
                "templateVars": $optAttrs["templateVars"],
                "attrs": _templates.formatAttributes($optAttrs, ["text", "value"]),
            ]);
        }

        return $out;
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
            $selected = $selected == false ? "0" : $selected;

            return $key == (string)$selected;
        }
        $strict = !is_numeric($key);

        return in_array($key, $selected, $strict);
    }

    /**
     * Helper method for deciding what options are disabled.
     *
     * @param string aKey The key to test.
     * @param array<string>|null $disabled The disabled values.
     */
    protected bool _isDisabled(string aKey, ?array $disabled) {
        if ($disabled == null) {
            return false;
        }
        $strict = !is_numeric($key);

        return in_array($key, $disabled, $strict);
    }
}
