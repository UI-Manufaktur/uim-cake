module uim.cake.consoles.consoleinputoption;

@safe:
import uim.cake;

/**
 * An object to represent a single option used in the command line.
 * ConsoleOptionParser creates these when you use addOption()
 *
 * @see uim.cake.consoles.ConsoleOptionParser::addOption()
 */
class ConsoleInputOption {
    // Name of the option
    protected string _name;

    // Short (1 character) alias for the option.
    protected string _short;

    // Help text for the option.
    protected string _help;

    // Is the option a boolean option. Boolean options do not consume a parameter.
    protected bool $_boolean;

    /**
     * Default value for the option
     *
     * @var string|bool|null
     */
    protected _default;

    // Can the option accept multiple value definition.
    protected bool $_multiple;

    /**
     * An array of choices for the option.
     *
     * @var array<string>
     */
    protected _choices;

    // Is the option required.
    protected bool $required;

    /**
     * Make a new Input Option
     *
     * @param string myName The long name of the option, or an array with all the properties.
     * @param string short The short alias for this option
     * @param string help The help text for this option
     * @param bool $isBoolean Whether this option is a boolean option. Boolean options don"t consume extra tokens
     * @param string|bool|null $default The default value for this option.
     * @param array<string> $choices Valid choices for this option.
     * @param bool $multiple Whether this option can accept multiple value definition.
     * @param bool $required Whether this option is required or not.
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    this(
      string myName,
      string short = "",
      string help = "",
      bool $isBoolean = false,
      $default = null,
      array $choices = [],
      bool $multiple = false,
      bool $required = false
    ) {
        _name = myName;
        _short = $short;
        _help = $help;
        _boolean = $isBoolean;
        _choices = $choices;
        _multiple = $multiple;
        this.required = $required;

        if ($isBoolean) {
            _default = (bool)$default;
        } elseif ($default  !is null) {
            _default = (string)$default;
        }

        if (strlen(_short) > 1) {
          throw new ConsoleException(
            sprintf("Short option "%s" is invalid, short options must be one letter.", _short)
          );
        }
    }

    // Get the value of the name attribute.
    string name() {
        return _name;
    }

    // Get the value of the short attribute.
    string short() {
        return _short;
    }

    /**
     * Generate the help for this this option.
     *
     * @param int $width The width to make the name of the option.
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
            $short = ", -" ~ _short;
        }
        myName = sprintf("--%s%s", name, $short);
        if (strlen(myName) < $width) {
            myName = str_pad(myName, $width, " ");
        }
        $required = "";
        if (this.isRequired()) {
            $required = " <comment>(required)</comment>";
        }

        return sprintf("%s%s%s%s", myName, _help, $default, $required);
    }

    /**
     * Get the usage value for this option
     */
    string usage() {
        myName = _short == "" ? "--" ~ name : "-" ~ _short;
        $default = "";
        if (_default  !is null && !is_bool(_default) && _default != "") {
            $default = " " ~ _default;
        }
        if (_choices) {
            $default = " " ~ implode("|", _choices);
        }
        myTemplate = "[%s%s]";
        if (this.isRequired()) {
            myTemplate = "%s%s";
        }

        return sprintf(myTemplate, myName, $default);
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
    bool isRequired() {
        return this.required;
    }

    /**
     * Check if this option is a boolean option
    bool isBoolean() {
        return _boolean;
    }

    /**
     * Check if this option accepts multiple values.
    bool acceptsMultiple() {
        return _multiple;
    }

    /**
     * Check that a value is a valid choice for this option.
     *
     * @param string|bool myValue The choice to validate.
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    bool validChoice(myValue) {
        if (empty(_choices)) {
            return true;
        }
        if (!in_array(myValue, _choices, true)) {
            throw new ConsoleException(
                sprintf(
                    ""%s" is not a valid value for --%s. Please use one of "%s"",
                    (string)myValue,
                    name,
                    implode(", ", _choices)
                )
            );
        }

        return true;
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
        $option.addAttribute("name", "--" ~ name);
        $short = "";
        if (_short != "") {
            $short = "-" ~ _short;
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
