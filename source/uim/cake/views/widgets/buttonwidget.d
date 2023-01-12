module uim.cake.views\Widget;

import uim.cake.views\Form\IContext;
import uim.cake.views\StringTemplate;

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
     * @var uim.cake.views\StringTemplate
     */
    protected _templates;

    /**
     * Constructor.
     *
     * @param uim.cake.views\StringTemplate $templates Templates list.
     */
    this(StringTemplate $templates) {
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
     * - `type` The button type defaults to "submit".
     *
     * Any other keys provided in $data will be converted into HTML attributes.
     *
     * @param array<string, mixed> $data The data to build a button with.
     * @param uim.cake.views\Form\IContext $context The current form context.
     */
    string render(array $data, IContext $context) {
        $data += [
            "text": "",
            "type": "submit",
            "escapeTitle": true,
            "escape": true,
            "templateVars": [],
        ];

        return _templates.format("button", [
            "text": $data["escapeTitle"] ? h($data["text"]) : $data["text"],
            "templateVars": $data["templateVars"],
            "attrs": _templates.formatAttributes($data, ["text", "escapeTitle"]),
        ]);
    }


    array secureFields(array $data) {
        if (!isset($data["name"]) || $data["name"] == "") {
            return [];
        }

        return [$data["name"]];
    }
}
