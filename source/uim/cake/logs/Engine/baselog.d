/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.logs.Engine;

use ArrayObject;
import uim.cake.core.InstanceConfigTrait;
import uim.cake.logs.Formatter\AbstractFormatter;
import uim.cake.logs.Formatter\DefaultFormatter;
use InvalidArgumentException;
use JsonSerializable;
use Psr\logs.AbstractLogger;
use Serializable;

/**
 * Base log engine class.
 */
abstract class BaseLog : AbstractLogger
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "levels": [],
        "scopes": [],
        "formatter": DefaultFormatter::class,
    ];

    /**
     * @var uim.cake.logs.Formatter\AbstractFormatter
     */
    protected $formatter;

    /**
     * __construct method
     *
     * @param array<string, mixed> aConfig Configuration array
     */
    this(Json aConfig = null) {
        this.setConfig(aConfig);

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
                $class = $formatter["className"];
                $options = $formatter;
            } else {
                $class = $formatter;
                $options = null;
            }
            /** @var class-string<uim.cake.logs.Formatter\AbstractFormatter> $class */
            $formatter = new $class($options);
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

    /**
     * Get the levels this logger is interested in.
     *
     * @return array<string>
     */
    array levels() {
        return _config["levels"];
    }

    /**
     * Get the scopes this logger is interested in.
     *
     * @return array<string>|false
     */
    function scopes() {
        return _config["scopes"];
    }

    /**
     * Formats the message to be logged.
     *
     * The context can optionally be used by log engines to interpolate variables
     * or add additional info to the logged message.
     *
     * @param string $message The message to be formatted.
     * @param array $context Additional logging information for the message.
     * @return string
     * @deprecated 4.3.0 Call `interpolate()` directly from your log engine and format the message in a formatter.
     */
    protected string _format(string $message, array $context = null) {
        return this.interpolate($message, $context);
    }

    /**
     * Replaces placeholders in message string with context values.
     *
     * @param string $message Formatted string
     * @param array $context Context for placeholder values.
     */
    protected string interpolate(string $message, array $context = null) {
        if (strpos($message, "{") == false && strpos($message, "}") == false) {
            return $message;
        }

        preg_match_all(
            "/(?<!" ~ preg_quote("\\", "/") ~ ")\{([a-z0-9-_]+)\}/i",
            $message,
            $matches
        );
        if (empty($matches)) {
            return $message;
        }

        $placeholders = array_intersect($matches[1], array_keys($context));
        $replacements = null;

        foreach ($placeholders as $key) {
            $value = $context[$key];

            if (is_scalar($value)) {
                $replacements["{" ~ $key ~ "}"] = (string)$value;
                continue;
            }

            if (is_array($value)) {
                $replacements["{" ~ $key ~ "}"] = json_encode($value, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if ($value instanceof JsonSerializable) {
                $replacements["{" ~ $key ~ "}"] = json_encode($value, JSON_UNESCAPED_UNICODE);
                continue;
            }

            if ($value instanceof ArrayObject) {
                $replacements["{" ~ $key ~ "}"] = json_encode($value.getArrayCopy(), JSON_UNESCAPED_UNICODE);
                continue;
            }

            if ($value instanceof Serializable) {
                $replacements["{" ~ $key ~ "}"] = $value.serialize();
                continue;
            }

            if (is_object($value)) {
                if (method_exists($value, "toArray")) {
                    $replacements["{" ~ $key ~ "}"] = json_encode($value.toArray(), JSON_UNESCAPED_UNICODE);
                    continue;
                }

                if (method_exists($value, "__serialize")) {
                    $replacements["{" ~ $key ~ "}"] = serialize($value);
                    continue;
                }

                if (method_exists($value, "__toString")) {
                    $replacements["{" ~ $key ~ "}"] = (string)$value;
                    continue;
                }

                if (method_exists($value, "__debugInfo")) {
                    $replacements["{" ~ $key ~ "}"] = json_encode($value.__debugInfo(), JSON_UNESCAPED_UNICODE);
                    continue;
                }
            }

            $replacements["{" ~ $key ~ "}"] = sprintf("[unhandled value of type %s]", getTypeName($value));
        }

        /** @psalm-suppress InvalidArgument */
        return replace(array_keys($replacements), $replacements, $message);
    }
}
