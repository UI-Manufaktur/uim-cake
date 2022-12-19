module uim.cake.views.widgets;

@safe:
import uim.cake;

/**
 * Input widget class for generating a date time input widget.
 *
 * This class is usually used internally by `Cake\View\Helper\FormHelper`,
 * it but can be used to generate standalone date time inputs.
 */
class DateTimeWidget : BasicWidget {
    /**
     * Template instance.
     *
     * @var \Cake\View\StringTemplate
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
        "type": "datetime-local",
        "escape": true,
        "timezone": null,
        "templateVars": [],
    ];

    /**
     * Formats for various input types.
     *
     * @var array<string>
     */
    protected $formatMap = [
        "datetime-local": "Y-m-d\TH:i:s",
        "date": "Y-m-d",
        "time": "H:i:s",
        "month": "Y-m",
        "week": "Y-\WW",
    ];

    /**
     * Step size for various input types.
     *
     * If not set, defaults to browser default.
     *
     * @var array<string, mixed>
     */
    protected $defaultStep = [
        "datetime-local": "1",
        "date": null,
        "time": "1",
        "month": null,
        "week": null,
    ];

    /**
     * Render a date / time form widget.
     *
     * Data supports the following keys:
     *
     * - `name` The name attribute.
     * - `val` The value attribute.
     * - `escape` Set to false to disable escaping on all attributes.
     * - `type` A valid HTML date/time input type. Defaults to "datetime-local".
     * - `timezone` The timezone the input value should be converted to.
     * - `step` The "step" attribute. Defaults to `1` for "time" and "datetime-local" type inputs.
     *   You can set it to `null` or `false` to prevent explicit step attribute being added in HTML.
     * - `format` A `date()` function compatible datetime format string.
     *   By default, the widget will use a suitable format based on the input type and
     *   database type for the context. If an explicit format is provided, then no
     *   default value will be set for the `step` attribute, and it needs to be
     *   explicitly set if required.
     *
     * All other keys will be converted into HTML attributes.
     *
     * @param array<string, mixed> myData The data to build a file input with.
     * @param \Cake\View\Form\IContext $context The current form context.
     * @return string HTML elements.
     */
    string render(array myData, IContext $context) {
        myData += this.mergeDefaults(myData, $context);

        if (!isset(this.formatMap[myData["type"]])) {
            throw new InvalidArgumentException(sprintf(
                "Invalid type `%s` for input tag, expected datetime-local, date, time, month or week",
                myData["type"]
            ));
        }

        myData = this.setStep(myData, $context, myData["fieldName"] ?? "");

        myData["value"] = this.formatDateTime(myData["val"], myData);
        unset(myData["val"], myData["timezone"], myData["format"]);

        return _templates.format("input", [
            "name": myData["name"],
            "type": myData["type"],
            "templateVars": myData["templateVars"],
            "attrs": _templates.formatAttributes(
                myData,
                ["name", "type"]
            ),
        ]);
    }

    /**
     * Set value for "step" attribute if applicable.
     *
     * @param array<string, mixed> myData Data array
     * @param \Cake\View\Form\IContext $context Context instance.
     * @param string myFieldName Field name.
     * @return array<string, mixed> Updated data array.
     */
    protected auto setStep(array myData, IContext $context, string myFieldName): array
    {
        if (array_key_exists("step", myData)) {
            return myData;
        }

        if (isset(myData["format"])) {
            myData["step"] = null;
        } else {
            myData["step"] = this.defaultStep[myData["type"]];
        }

        if (empty(myData["fieldName"])) {
            return myData;
        }

        $dbType = $context.type(myFieldName);
        $fractionalTypes = [
            TableSchema::TYPE_DATETIME_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_FRACTIONAL,
            TableSchema::TYPE_TIMESTAMP_TIMEZONE,
        ];

        if (in_array($dbType, $fractionalTypes, true)) {
            myData["step"] = "0.001";
        }

        return myData;
    }

    /**
     * Formats the passed date/time value into required string format.
     *
     * @param \DateTime|string|int|null myValue Value to deconstruct.
     * @param array<string, mixed> myOptions Options for conversion.
     * @return string
     * @throws \InvalidArgumentException If invalid input type is passed.
     */
    protected string formatDateTime(myValue, array myOptions) {
        if (myValue == "" || myValue == null) {
            return "";
        }

        try {
            if (myValue instanceof IDateTime) {
                $dateTime = clone myValue;
            } elseif (is_string(myValue) && !is_numeric(myValue)) {
                $dateTime = new DateTime(myValue);
            } elseif (is_int(myValue) || is_numeric(myValue)) {
                $dateTime = new DateTime("@" . myValue);
            } else {
                $dateTime = new DateTime();
            }
        } catch (Exception $e) {
            $dateTime = new DateTime();
        }

        if (isset(myOptions["timezone"])) {
            $timezone = myOptions["timezone"];
            if (!$timezone instanceof DateTimeZone) {
                $timezone = new DateTimeZone($timezone);
            }

            $dateTime = $dateTime.setTimezone($timezone);
        }

        if (isset(myOptions["format"])) {
          $format = myOptions["format"];
        } else {
            $format = this.formatMap[myOptions["type"]];

            if (
                myOptions["type"] == "datetime-local"
                && is_numeric(myOptions["step"])
                && myOptions["step"] < 1) {
                $format = "Y-m-d\TH:i:s.v";
            }
        }

        return $dateTime.format($format);
    }

    function secureFields(array myData): array
    {
        if (!isset(myData["name"]) || myData["name"] == "") {
            return [];
        }

        return [myData["name"]];
    }
}
