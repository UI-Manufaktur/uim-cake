module uim.cake.View\Widget;

import uim.cake.View\Form\IContext;

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
     * @param array<string, mixed> $data The data to build a textarea with.
     * @param uim.cake.View\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    string render(array $data, IContext $context) {
        $data += this.mergeDefaults($data, $context);

        if (
            !array_key_exists("maxlength", $data)
            && isset($data["fieldName"])
        ) {
            $data = this.setMaxLength($data, $context, $data["fieldName"]);
        }

        return _templates.format("textarea", [
            "name": $data["name"],
            "value": $data["escape"] ? h($data["val"]) : $data["val"],
            "templateVars": $data["templateVars"],
            "attrs": _templates.formatAttributes(
                $data,
                ["name", "val"]
            ),
        ]);
    }
}
