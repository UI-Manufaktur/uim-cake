/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.logs.engines;

@safe:
import uim.cake;

// Base log engine class.
abstract class BaseLog : AbstractLogger {
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "levels":[],
        "scopes":[],
        "formatter":DefaultFormatter::class,
    ];

    /**
     * @var uim.cake.logs.Formatter\AbstractFormatter
     */
    protected formatter;

    /**
     * __construct method
     *
     * @param array<string, mixed> myConfig Configuration array
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);

        if (!is_array(_config["scopes"]) && _config["scopes"] != false) {
            _config["scopes"] = (array)_config["scopes"];
        }

        if (!is_array(_config["levels"])) {
            _config["levels"] = (array)_config["levels"];
        }

        if (!empty(_config["types"]) && empty(_config["levels"])) {
            _config["levels"] = (array)_config["types"];
        }

        $formatter = _config["formatter"] ?? DefaultFormatter::class;
        if (!is_object($formatter)) {
            if (is_array($formatter)) {
                myClass = $formatter["className"];
                myOptions = $formatter;
            } else {
                myClass = $formatter;
                myOptions = [];
            }
            /** @var class-string<uim.cake.logs.Formatter\AbstractFormatter> myClass */
            $formatter = new myClass(myOptions);
        }

        if (!$formatter instanceof AbstractFormatter) {
            throw new InvalidArgumentException(sprintf(
                "Formatter must extend `%s`, got `%s` instead",
                AbstractFormatter::class,
                get_class($formatter)
            ));
        }
        this.formatter = $formatter;
    }

    // Get the levels this logger is interested in.
    string[] levels() {
        return _config["levels"];
    }

    // Get the scopes this logger is interested in.
    string[] scopes() {
        return _config["scopes"];
    }

    /**
     * Formats the message to be logged.
     *
     * The context can optionally be used by log engines to interpolate variables
     * or add additional info to the logged message.
     *
     * @param string myMessage The message to be formatted.
     * @param array $context Additional logging information for the message.
     * @return string
     * @deprecated 4.3.0 Call `interpolate()` directly from your log engine and format the message in a formatter.
     */
    protected string _format(string myMessage, array $context = []) {
        return this.interpolate(myMessage, $context);
    }

    /**
     * Replaces placeholders in message string with context values.
     *
     * @param string myMessage Formatted string
     * @param array $context Context for placeholder values.
     * @return string
     */
    protected string interpolate(string myMessage, array $context = []) {
        if (indexOf(myMessage, "{") == false && indexOf(myMessage, "}") == false) {
            return myMessage;
        }

        preg_match_all(
            "/(?<!" . preg_quote("\\", "/") . ")\{([a-z0-9-_]+)\}/i",
            myMessage,
            $matches
        );
        if (empty($matches)) {
            return myMessage;
        }

        $placeholders = array_intersect($matches[1], array_keys($context));
        $replacements = [];

        foreach ($placeholders as myKey) {
            myValue = $context[myKey];

            if (is_scalar(myValue)) {
                $replacements["{" . myKey . "}"] = (string)myValue;
                continue;
            }

            if (is_array(myValue)) {
                $replacements["{" . myKey . "}"] = json_encode(myValue, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof JsonSerializable) {
                $replacements["{" . myKey . "}"] = json_encode(myValue, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof ArrayObject) {
                $replacements["{" . myKey . "}"] = json_encode(myValue.getArrayCopy(), JSON_UNESCAPED_UNICODE);
                continue;
            }

            if (myValue instanceof Serializable) {
                $replacements["{" . myKey . "}"] = myValue.serialize();
                continue;
            }

            if (is_object(myValue)) {
                if (method_exists(myValue, "toArray")) {
                    $replacements["{" . myKey . "}"] = json_encode(myValue.toArray(), JSON_UNESCAPED_UNICODE);
                    continue;
                }

                if (method_exists(myValue, "__serialize")) {
                    $replacements["{" . myKey . "}"] = serialize(myValue);
                    continue;
                }

                if (method_exists(myValue, "__toString")) {
                    $replacements["{" . myKey . "}"] = (string)myValue;
                    continue;
                }

                if (method_exists(myValue, "__debugInfo")) {
                    $replacements["{" . myKey . "}"] = json_encode(myValue.__debugInfo(), JSON_UNESCAPED_UNICODE);
                    continue;
                }
            }

            $replacements["{" . myKey . "}"] = sprintf("[unhandled value of type %s]", getTypeName(myValue));
        }

        /** @psalm-suppress InvalidArgument */
        return str_replace(array_keys($replacements), $replacements, myMessage);
    }
}
