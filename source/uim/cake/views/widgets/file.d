module uim.cake.views.widgets;

@safe:
import uim.cake;

/**
 * Input widget class for generating a file upload control.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone file upload controls.
 */
class FileWidget : BasicWidget
{
    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "escape": true,
        "templateVars": [],
    ];

    /**
     * Render a file upload form widget.
     *
     * Data supports the following keys:
     *
     * - `name` - Set the input name.
     * - `escape` - Set to false to disable HTML escaping.
     *
     * All other keys will be converted into HTML attributes.
     * Unlike other input objects the `val` property will be specifically
     * ignored.
     *
     * @param array<string, mixed> myData The data to build a file input with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    string render(array myData, IContext $context) {
        myData += this.mergeDefaults(myData, $context);

        unset(myData["val"]);

        return this._templates.format("file", [
            "name": myData["name"],
            "templateVars": myData["templateVars"],
            "attrs": this._templates.formatAttributes(
                myData,
                ["name"]
            ),
        ]);
    }

    /**
     * @inheritDoc
     */
    function secureFields(array myData): array
    {
        // PSR7 UploadedFileInterface objects are used.
        if (Configure::read("App.uploadedFilesAsObjects", true)) {
            return [myData["name"]];
        }

        // Backwards compatibility for array files.
        myFields = [];
        foreach (["name", "type", "tmp_name", "error", "size"] as $suffix) {
            myFields[] = myData["name"] . "[" . $suffix . "]";
        }

        return myFields;
    }
}
