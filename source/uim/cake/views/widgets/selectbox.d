/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.viewss.widgets;

@safe:
import uim.cake;

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
    protected defaults = [
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
     * @param array<string, mixed> myData Data to render with.
     * @param uim.cake.views\Form\IContext $context The current form context.
     * @return string A generated select box.
     * @throws \RuntimeException when the name attribute is empty.
     */
    string render(array myData, IContext $context) {
        myData += this.mergeDefaults(myData, $context);

        myOptions = _renderContent(myData);
        myName = myData["name"];
        unset(myData["name"], myData["options"], myData["empty"], myData["val"], myData["escape"]);
        if (isset(myData["disabled"]) && is_array(myData["disabled"])) {
            unset(myData["disabled"]);
        }

        myTemplate = "select";
        if (!empty(myData["multiple"])) {
            myTemplate = "selectMultiple";
            unset(myData["multiple"]);
        }
        $attrs = _templates.formatAttributes(myData);

        return _templates.format(myTemplate, [
            "name": myName,
            "templateVars": myData["templateVars"],
            "attrs": $attrs,
            "content": implode("", myOptions),
        ]);
    }

    /**
     * Render the contents of the select element.
     * @param array<string, mixed> myData The context for rendering a select.
     */
    protected string[] _renderContent(array myData) {
        myOptions = myData["options"];

        if (myOptions instanceof Traversable) {
            myOptions = iterator_to_array(myOptions);
        }

        if (!empty(myData["empty"])) {
            myOptions = _emptyValue(myData["empty"]) + (array)myOptions;
        }
        if (empty(myOptions)) {
            return [];
        }

        $selected = myData["val"] ?? null;
        $disabled = null;
        if (isset(myData["disabled"]) && is_array(myData["disabled"])) {
            $disabled = myData["disabled"];
        }
        myTemplateVars = myData["templateVars"];

        return _renderOptions(myOptions, $disabled, $selected, myTemplateVars, myData["escape"]);
    }

    /**
     * Generate the empty value based on the input.
     *
     * @param array|string|bool myValue The provided empty value.
     * @return array The generated option key/value.
     */
    protected array _emptyValue(myValue) {
        if (myValue == true) {
            return ["": ""];
        }
        if (is_scalar(myValue)) {
            return ["": myValue];
        }
        if (is_array(myValue)) {
            return myValue;
        }

        return [];
    }

    /**
     * Render the contents of an optgroup element.
     *
     * @param string label The optgroup label text
     * @param \ArrayAccess|array $optgroup The opt group data.
     * @param array|null $disabled The options to disable.
     * @param array|string|null $selected The options to select.
     * @param array myTemplateVars Additional template variables.
     * @param bool $escape Toggle HTML escaping
     * @return string Formatted template string
     */
    protected string _renderOptgroup(
        string label,
        $optgroup,
        ?array $disabled,
        $selected,
        myTemplateVars,
        $escape
    ) {
        $opts = $optgroup;
        $attrs = null;
        if (isset($optgroup["options"], $optgroup["text"])) {
            $opts = $optgroup["options"];
            $label = $optgroup["text"];
            $attrs = (array)$optgroup;
        }
        myGroupOptions = _renderOptions($opts, $disabled, $selected, myTemplateVars, $escape);

        return _templates.format("optgroup", [
            "label": $escape ? h($label) : $label,
            "content": implode("", myGroupOptions),
            "templateVars": myTemplateVars,
            "attrs": _templates.formatAttributes($attrs, ["text", "options"]),
        ]);
    }

    /**
     * Render a set of options.
     *
     * Will recursively call itself when option groups are in use.
     *
     * @param iterable myOptions The options to render.
     * @param array<string>|null $disabled The options to disable.
     * @param array|string|null $selected The options to select.
     * @param array myTemplateVars Additional template variables.
     * @param bool $escape Toggle HTML escaping.
     * @return Option elements.
     */
    protected string[] _renderOptions(iterable myOptions, ?array $disabled, $selected, myTemplateVars, $escape) {
        $out = null;
        foreach (myOptions as myKey: $val) {
            // Option groups
            $isIterable = is_iterable($val);
            if (
                (
                    !is_int(myKey) &&
                    $isIterable
                ) ||
                (
                    is_int(myKey) &&
                    $isIterable &&
                    (
                        isset($val["options"]) ||
                        !isset($val["value"])
                    )
                )
            ) {
                $out[] = _renderOptgroup((string)myKey, $val, $disabled, $selected, myTemplateVars, $escape);
                continue;
            }

            // Basic options
            $optAttrs = [
                "value": myKey,
                "text": $val,
                "templateVars": [],
            ];
            if (is_array($val) && isset($val["text"], $val["value"])) {
                $optAttrs = $val;
                myKey = $optAttrs["value"];
            }
            $optAttrs["templateVars"] = $optAttrs["templateVars"] ?? [];
            if (_isSelected((string)myKey, $selected)) {
                $optAttrs["selected"] = true;
            }
            if (_isDisabled((string)myKey, $disabled)) {
                $optAttrs["disabled"] = true;
            }
            if (!empty(myTemplateVars)) {
                $optAttrs["templateVars"] = array_merge(myTemplateVars, $optAttrs["templateVars"]);
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
     * @param string myKey The key to test.
     * @param array<string>|string|int|false|null $selected The selected values.
     */
    protected bool _isSelected(string myKey, $selected) {
        if ($selected is null) {
            return false;
        }
        if (!is_array($selected)) {
            $selected = $selected == false ? "0" : $selected;

            return myKey == (string)$selected;
        }
        $strict = !is_numeric(myKey);

        return hasAllValues(myKey, $selected, $strict);
    }

    /**
     * Helper method for deciding what options are disabled.
     *
     * @param string myKey The key to test.
     * @param array<string>|null $disabled The disabled values.
     */
    protected bool _isDisabled(string myKey, ?array $disabled) {
        if ($disabled is null) {
            return false;
        }
        $strict = !is_numeric(myKey);

        return hasAllValues(myKey, $disabled, $strict);
    }
}
