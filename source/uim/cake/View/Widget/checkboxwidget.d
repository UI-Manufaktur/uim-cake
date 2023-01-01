module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;

/**
 * Input widget for creating checkbox widgets.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone checkboxes.
 */
class CheckboxWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "value": 1,
        "val": null,
        "disabled": false,
        "templateVars": [],
    ];

    /**
     * Render a checkbox element.
     *
     * Data supports the following keys:
     *
     * - `name` - The name of the input.
     * - `value` - The value attribute. Defaults to "1".
     * - `val` - The current value. If it matches `value` the checkbox will be checked.
     *   You can also use the "checked" attribute to make the checkbox checked.
     * - `disabled` - Whether the checkbox should be disabled.
     *
     * Any other attributes passed in will be treated as HTML attributes.
     *
     * @param array<string, mixed> $data The data to create a checkbox with.
     * @param uim.cake.View\Form\ContextInterface $context The current form context.
     * @return string Generated HTML string.
     */
    function render(array $data, ContextInterface $context): string
    {
        $data += this.mergeDefaults($data, $context);

        if (_isChecked($data)) {
            $data["checked"] = true;
        }
        unset($data["val"]);

        $attrs = _templates.formatAttributes(
            $data,
            ["name", "value"]
        );

        return _templates.format("checkbox", [
            "name": $data["name"],
            "value": $data["value"],
            "templateVars": $data["templateVars"],
            "attrs": $attrs,
        ]);
    }

    /**
     * Checks whether the checkbox should be checked.
     *
     * @param array<string, mixed> $data Data to look at and determine checked state.
     */
    protected bool _isChecked(array $data): bool
    {
        if (array_key_exists("checked", $data)) {
            return (bool)$data["checked"];
        }

        return (string)$data["val"] == (string)$data["value"];
    }
}