module uim.cake.viewss.widgetss;

@safe:
import uim.cake;

/**
 * Button input class
 *
 * This input class can be used to render button elements.
 * If you need to make basic submit inputs with type=submit,
 * use the Basic input widget.
 */
class ButtonWidget : IWidget
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
     * @param uim.cake.views\StringTemplate myTemplates Templates list.
     */
    this(StringTemplate myTemplates) {
        _templates = myTemplates;
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
     * Any other keys provided in myData will be converted into HTML attributes.
     *
     * @param array<string, mixed> myData The data to build a button with.
     * @param uim.cake.views\Form\IContext $context The current form context.
     */
    string render(array myData, IContext $context) {
        myData += [
            "text": "",
            "type": "submit",
            "escapeTitle": true,
            "escape": true,
            "templateVars": [],
        ];

        return _templates.format("button", [
            "text": myData["escapeTitle"] ? h(myData["text"]) : myData["text"],
            "templateVars": myData["templateVars"],
            "attrs": _templates.formatAttributes(myData, ["text", "escapeTitle"]),
        ]);
    }


    array secureFields(array myData) {
        if (!isset(myData["name"]) || myData["name"] == "") {
            return [];
        }

        return [myData["name"]];
    }
}
