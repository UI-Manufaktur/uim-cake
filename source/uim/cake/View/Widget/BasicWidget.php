module uim.cake.View\Widget;

import uim.cake.View\Form\ContextInterface;
import uim.cake.View\StringTemplate;

/**
 * Basic input class.
 *
 * This input class can be used to render basic simple
 * input elements like hidden, text, email, tel and other
 * types.
 */
class BasicWidget : WidgetInterface
{
    /**
     * StringTemplate instance.
     *
     * @var uim.cake.View\StringTemplate
     */
    protected $_templates;

    /**
     * Data defaults.
     *
     * @var array<string, mixed>
     */
    protected $defaults = [
        "name": "",
        "val": null,
        "type": "text",
        "escape": true,
        "templateVars": [],
    ];

    /**
     * Constructor.
     *
     * @param uim.cake.View\StringTemplate $templates Templates list.
     */
    this(StringTemplate $templates) {
        _templates = $templates;
    }

    /**
     * Render a text widget or other simple widget like email/tel/number.
     *
     * This method accepts a number of keys:
     *
     * - `name` The name attribute.
     * - `val` The value attribute.
     * - `escape` Set to false to disable escaping on all attributes.
     *
     * Any other keys provided in $data will be converted into HTML attributes.
     *
     * @param array<string, mixed> $data The data to build an input with.
     * @param uim.cake.View\Form\ContextInterface $context The current form context.
     */
    string render(array $data, ContextInterface $context): string
    {
        $data = this.mergeDefaults($data, $context);

        $data["value"] = $data["val"];
        unset($data["val"]);
        if ($data["value"] == false) {
            // explicitly convert to 0 to avoid empty string which is marshaled as null
            $data["value"] = "0";
        }

        $fieldName = $data["fieldName"] ?? null;
        if ($fieldName) {
            if ($data["type"] == "number" && !isset($data["step"])) {
                $data = this.setStep($data, $context, $fieldName);
            }

            $typesWithMaxLength = ["text", "email", "tel", "url", "search"];
            if (
                !array_key_exists("maxlength", $data)
                && in_array($data["type"], $typesWithMaxLength, true)
            ) {
                $data = this.setMaxLength($data, $context, $fieldName);
            }
        }

        return _templates.format("input", [
            "name": $data["name"],
            "type": $data["type"],
            "templateVars": $data["templateVars"],
            "attrs": _templates.formatAttributes(
                $data,
                ["name", "type"]
            ),
        ]);
    }

    /**
     * Merge default values with supplied data.
     *
     * @param array<string, mixed> $data Data array
     * @param uim.cake.View\Form\ContextInterface $context Context instance.
     * @return array<string, mixed> Updated data array.
     */
    protected function mergeDefaults(array $data, ContextInterface $context): array
    {
        $data += this.defaults;

        if (isset($data["fieldName"]) && !array_key_exists("required", $data)) {
            $data = this.setRequired($data, $context, $data["fieldName"]);
        }

        return $data;
    }

    /**
     * Set value for "required" attribute if applicable.
     *
     * @param array<string, mixed> $data Data array
     * @param uim.cake.View\Form\ContextInterface $context Context instance.
     * @param string $fieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected function setRequired(array $data, ContextInterface $context, string $fieldName): array
    {
        if (
            empty($data["disabled"])
            && (
                (isset($data["type"])
                    && $data["type"] != "hidden"
                )
                || !isset($data["type"])
            )
            && $context.isRequired($fieldName)
        ) {
            $data["required"] = true;
        }

        return $data;
    }

    /**
     * Set value for "maxlength" attribute if applicable.
     *
     * @param array<string, mixed> $data Data array
     * @param uim.cake.View\Form\ContextInterface $context Context instance.
     * @param string $fieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected function setMaxLength(array $data, ContextInterface $context, string $fieldName): array
    {
        $maxLength = $context.getMaxLength($fieldName);
        if ($maxLength != null) {
            $data["maxlength"] = min($maxLength, 100000);
        }

        return $data;
    }

    /**
     * Set value for "step" attribute if applicable.
     *
     * @param array<string, mixed> $data Data array
     * @param uim.cake.View\Form\ContextInterface $context Context instance.
     * @param string $fieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected function setStep(array $data, ContextInterface $context, string $fieldName): array
    {
        $dbType = $context.type($fieldName);
        $fieldDef = $context.attributes($fieldName);

        if ($dbType == "decimal" && isset($fieldDef["precision"])) {
            $decimalPlaces = $fieldDef["precision"];
            $data["step"] = sprintf("%." . $decimalPlaces . "F", pow(10, -1 * $decimalPlaces));
        } elseif ($dbType == "float") {
            $data["step"] = "any";
        }

        return $data;
    }


    function secureFields(array $data): array
    {
        if (!isset($data["name"]) || $data["name"] == "") {
            return [];
        }

        return [$data["name"]];
    }
}
