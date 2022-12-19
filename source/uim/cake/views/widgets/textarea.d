module uim.cake.views.widgets;

@safe:
import uim.cake;

/**
 * Input widget class for generating a textarea control.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone text areas.
 */
class TextareaWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "val": "",
        "name": "",
        "escape": true,
        "rows": 5,
        "templateVars": [],
    ];

    /**
     * Render a text area form widget.
     *
     * Data supports the following keys:
     *
     * - `name` - Set the input name.
     * - `val` - A string of the option to mark as selected.
     * - `escape` - Set to false to disable HTML escaping.
     *
     * All other keys will be converted into HTML attributes.
     *
     * @param array<string, mixed> myData The data to build a textarea with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    string render(array myData, IContext $context) {
        myData += this.mergeDefaults(myData, $context);

        if (
            !array_key_exists("maxlength", myData)
            && isset(myData["fieldName"])
        ) {
            myData = this.setMaxLength(myData, $context, myData["fieldName"]);
        }

        return _templates.format("textarea", [
            "name": myData["name"],
            "value": myData["escape"] ? h(myData["val"]) : myData["val"],
            "templateVars": myData["templateVars"],
            "attrs": _templates.formatAttributes(
                myData,
                ["name", "val"]
            ),
        ]);
    }
}
