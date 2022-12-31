module uim.cake.Console;

import uim.cake.consoles.exceptions.ConsoleException;
use SimpleXMLElement;

/**
 * An object to represent a single option used in the command line.
 * ConsoleOptionParser creates these when you use addOption()
 *
 * @see uim.cake.consoles.ConsoleOptionParser::addOption()
 */
class ConsoleInputOption
{
    // Name of the option
    protected string $_name;

    // Short (1 character) alias for the option.
    protected string $_short;

    // Help text for the option.
    protected string $_help;

    // Is the option a boolean option. Boolean options do not consume a parameter.
    protected bool $_boolean;

    /**
     * Default value for the option
     *
     * @var string|bool|null
     */
    protected $_default;

    // Can the option accept multiple value definition.
    protected bool $_multiple;

    /**
     * An array of choices for the option.
     *
     * @var array<string>
     */
    protected $_choices;

    /**
     * The prompt string
     *
     * @var string|null
     */
    protected $prompt;

    /**
     * Is the option required.
     *
     */
    protected bool $required;

    /**
     * Make a new Input Option
     *
     * @param string aName The long name of the option, or an array with all the properties.
     * @param string $short The short alias for this option
     * @param string $help The help text for this option
     * @param bool $isBoolean Whether this option is a boolean option. Boolean options don"t consume extra tokens
     * @param string|bool|null $default The default value for this option.
     * @param array<string> $choices Valid choices for this option.
     * @param bool $multiple Whether this option can accept multiple value definition.
     * @param bool $required Whether this option is required or not.
     * @param string|null $prompt The prompt string.
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    this(
        string aName,
        string $short = "",
        string $help = "",
        bool $isBoolean = false,
        $default = null,
        array $choices = [],
        bool $multiple = false,
        bool $required = false,
        ?string $prompt = null
    ) {
        _name = $name;
        _short = $short;
        _help = $help;
        _boolean = $isBoolean;
        _choices = $choices;
        _multiple = $multiple;
        this.required = $required;
        this.prompt = $prompt;

        if ($isBoolean) {
            _default = (bool)$default;
        } elseif ($default != null) {
            _default = (string)$default;
        }

        if (strlen(_short) > 1) {
            throw new ConsoleException(
                sprintf("Short option "%s" is invalid, short options must be one letter.", _short)
            );
        }
        if (isset(_default) && this.prompt) {
            throw new ConsoleException(
                "You cannot set both `prompt` and `default` options. " .
                "Use either a static `default` or interactive `prompt`"
            );
        }
    }

    /**
     * Get the value of the name attribute.
     *
     * @return string Value of _name.
     */
    string name() {
        return _name;
    }

    /**
     * Get the value of the short attribute.
     *
     * @return string Value of _short.
     */
    string short() {
        return _short;
    }

    /**
     * Generate the help for this this option.
     *
     * @param int $width The width to make the name of the option.
     * @return string
     */
    string help(int $width = 0) {
        $default = $short = "";
        if (_default && _default != true) {
            $default = sprintf(" <comment>(default: %s)</comment>", _default);
        }
        if (_choices) {
            $default .= sprintf(" <comment>(choices: %s)</comment>", implode("|", _choices));
        }
        if (_short != "") {
            $short = ", -" . _short;
        }
        $name = sprintf("--%s%s", _name, $short);
        if (strlen($name) < $width) {
            $name = str_pad($name, $width, " ");
        }
        $required = "";
        if (this.isRequired()) {
            $required = " <comment>(required)</comment>";
        }

        return sprintf("%s%s%s%s", $name, _help, $default, $required);
    }

    /**
     * Get the usage value for this option
     */
    string usage() {
        $name = _short == "" ? "--" . _name : "-" . _short;
        $default = "";
        if (_default != null && !is_bool(_default) && _default != "") {
            $default = " " . _default;
        }
        if (_choices) {
            $default = " " . implode("|", _choices);
        }
        $template = "[%s%s]";
        if (this.isRequired()) {
            $template = "%s%s";
        }

        return sprintf($template, $name, $default);
    }

    /**
     * Get the default value for this option
     *
     * @return string|bool|null
     */
    function defaultValue() {
        return _default;
    }

    /**
     * Check if this option is required
     *
     * @return bool
     */
    bool isRequired() {
        return this.required;
    }

    /**
     * Check if this option is a boolean option
     *
     * @return bool
     */
    bool isBoolean() {
        return _boolean;
    }

    /**
     * Check if this option accepts multiple values.
     *
     * @return bool
     */
    bool acceptsMultiple() {
        return _multiple;
    }

    /**
     * Check that a value is a valid choice for this option.
     *
     * @param string|bool $value The choice to validate.
     * @return true
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    bool validChoice($value) {
        if (empty(_choices)) {
            return true;
        }
        if (!in_array($value, _choices, true)) {
            throw new ConsoleException(
                sprintf(
                    ""%s" is not a valid value for --%s. Please use one of "%s"",
                    (string)$value,
                    _name,
                    implode(", ", _choices)
                )
            );
        }

        return true;
    }

    /**
     * Get the list of choices this option has.
     */
    array choices(): array
    {
        return _choices;
    }

    /**
     * Get the prompt string
     */
    string prompt() {
        return (string)this.prompt;
    }

    /**
     * Append the option"s XML into the parent.
     *
     * @param \SimpleXMLElement $parent The parent element.
     * @return \SimpleXMLElement The parent with this option appended.
     */
    function xml(SimpleXMLElement $parent): SimpleXMLElement
    {
        $option = $parent.addChild("option");
        $option.addAttribute("name", "--" . _name);
        $short = "";
        if (_short != "") {
            $short = "-" . _short;
        }
        $default = _default;
        if ($default == true) {
            $default = "true";
        } elseif ($default == false) {
            $default = "false";
        }
        $option.addAttribute("short", $short);
        $option.addAttribute("help", _help);
        $option.addAttribute("boolean", (string)(int)_boolean);
        $option.addAttribute("required", (string)(int)this.required);
        $option.addChild("default", (string)$default);
        $choices = $option.addChild("choices");
        foreach (_choices as $valid) {
            $choices.addChild("choice", $valid);
        }

        return $parent;
    }
}
