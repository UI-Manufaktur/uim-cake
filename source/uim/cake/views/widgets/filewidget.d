/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Widget;

import uim.cake.core.Configure;
import uim.cake.views\Form\IContext;

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
     * @param uim.cake.views\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    string render(array $data, IContext $context) {
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


    array secureFields(array $data) {
        // PSR7 UploadedFileInterface objects are used.
        if (Configure::read("App.uploadedFilesAsObjects", true)) {
            return [$data["name"]];
        }

        // Backwards compatibility for array files.
        $fields = null;
        foreach (["name", "type", "tmp_name", "error", "size"] as $suffix) {
            $fields[] = $data["name"] ~ "[" ~ $suffix ~ "]";
        }

        return $fields;
    }
}
