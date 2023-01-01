module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;
import uim.cake.View\StringTemplate;

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
     * @var uim.cake.View\StringTemplate
     */
    protected $_templates;

    /**
     * The template to use.
     *
     */
    protected string $_labelTemplate = "label";

    /**
     * Constructor.
     *
     * This class uses the following template:
     *
     * - `label` Used to generate the label for a radio button.
     *   Can use the following variables `attrs`, `text` and `input`.
     *
     * @param uim.cake.View\StringTemplate $templates Templates list.
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
     * @param uim.cake.View\Form\ContextInterface $context The current form context.
     */
    string render(array $data, ContextInterface $context): string
    {
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


    function secureFields(array $data): array
    {
        return [];
    }
}
