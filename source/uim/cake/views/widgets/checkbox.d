module uim.cake.viewss.widgetss;

@safe:
import uim.cake;

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
    protected defaults = [
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
     * @param array<string, mixed> myData The data to create a checkbox with.
     * @param uim.cake.views\Form\IContext $context The current form context.
     * @return string Generated HTML string.
     */
    string render(array myData, IContext $context) {
        myData += this.mergeDefaults(myData, $context);

        if (_isChecked(myData)) {
            myData["checked"] = true;
        }
        unset(myData["val"]);

        $attrs = _templates.formatAttributes(
            myData,
            ["name", "value"]
        );

        return _templates.format("checkbox", [
            "name": myData["name"],
            "value": myData["value"],
            "templateVars": myData["templateVars"],
            "attrs": $attrs,
        ]);
    }

    /**
     * Checks whether the checkbox should be checked.
     *
     * @param array<string, mixed> myData Data to look at and determine checked state.
     */
    protected bool _isChecked(array myData) {
        if (array_key_exists("checked", myData)) {
            return (bool)myData["checked"];
        }

        return (string)myData["val"] == (string)myData["value"];
    }
}
