/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.views\Widget;

import uim.cake.views\Form\IContext;
import uim.cake.views\StringTemplate;

/**
 * Form "widget" for creating labels.
 *
 * Generally this element is used by other widgets,
 * and FormHelper itself.
 */
class LabelWidget : WidgetInterface
{
    /**
     * Templates
     *
     * @var uim.cake.views\StringTemplate
     */
    protected _templates;

    /**
     * The template to use.
     */
    protected string _labelTemplate = "label";

    /**
     * Constructor.
     *
     * This class uses the following template:
     *
     * - `label` Used to generate the label for a radio button.
     *   Can use the following variables `attrs`, `text` and `input`.
     *
     * @param uim.cake.views\StringTemplate $templates Templates list.
     */
    this(StringTemplate $templates) {
        _templates = $templates;
    }

    /**
     * Render a label widget.
     *
     * Accepts the following keys in $data:
     *
     * - `text` The text for the label.
     * - `input` The input that can be formatted into the label if the template allows it.
     * - `escape` Set to false to disable HTML escaping.
     *
     * All other attributes will be converted into HTML attributes.
     *
     * @param array<string, mixed> $data Data array.
     * @param uim.cake.views\Form\IContext $context The current form context.
     */
    string render(array $data, IContext $context) {
        $data += [
            "text": "",
            "input": "",
            "hidden": "",
            "escape": true,
            "templateVars": [],
        ];

        return _templates.format(_labelTemplate, [
            "text": $data["escape"] ? h($data["text"]) : $data["text"],
            "input": $data["input"],
            "hidden": $data["hidden"],
            "templateVars": $data["templateVars"],
            "attrs": _templates.formatAttributes($data, ["text", "input", "hidden"]),
        ]);
    }


    array secureFields(array $data) {
        return [];
    }
}
