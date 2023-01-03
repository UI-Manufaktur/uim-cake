module uim.cake.View\Widget;

import uim.cake.core.Configure;
import uim.cake.View\Form\IContext;

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
     * @param array<string, mixed> $data The data to build a file input with.
     * @param uim.cake.View\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    function render(array $data, IContext $context): string
    {
        $data += this.mergeDefaults($data, $context);

        unset($data["val"]);

        return _templates.format("file", [
            "name": $data["name"],
            "templateVars": $data["templateVars"],
            "attrs": _templates.formatAttributes(
                $data,
                ["name"]
            ),
        ]);
    }


    function secureFields(array $data): array
    {
        // PSR7 UploadedFileInterface objects are used.
        if (Configure::read("App.uploadedFilesAsObjects", true)) {
            return [$data["name"]];
        }

        // Backwards compatibility for array files.
        $fields = [];
        foreach (["name", "type", "tmp_name", "error", "size"] as $suffix) {
            $fields[] = $data["name"] ~ "[" ~ $suffix ~ "]";
        }

        return $fields;
    }
}
