module uim.cake.console;

@safe:
import uim.cake;

/**
 * An object to represent a single argument used in the command line.
 * ConsoleOptionParser creates these when you use addArgument()
 *
 * @see uim.cake.Console\ConsoleOptionParser::addArgument()
 */
class ConsoleInputArgument {
    // Name of the argument.
    protected string _name;
    // Get the value of the name attribute.
    @property string name() {
        return _name;
    }

    /**
     * Help string
     */
    protected string _help;

    // Is this option required?
    protected bool $_required;

    // An array of valid choices for this argument.
    protected string[] $_choices;

    /**
     * Make a new Input Argument
     *
     * @param array<string, mixed>|string myName The long name of the option, or an array with all the properties.
     * @param string help The help text for this option
     * @param bool $required Whether this argument is required. Missing required args will trigger exceptions
     * @param array<string> $choices Valid choices for this option.
     */
    this(myName, $help = "", $required = false, $choices = []) {
        if (is_array(myName) && isset(myName["name"])) {
            foreach (myKey, myValue; myName) {
                this.{"_" . myKey} = myValue;
            }
        } else {
            /** @psalm-suppress PossiblyInvalidPropertyAssignmentValue */
            _name = myName;
            _help = $help;
            _required = $required;
            _choices = $choices;
        }
    }


    /**
     * Checks if this argument is equal to another argument.
     *
     * @param uim.cake.Console\ConsoleInputArgument $argument ConsoleInputArgument to compare to.
     */
    bool isEqualTo(ConsoleInputArgument $argument) {
        return this.usage() == $argument.usage();
    }

    /**
     * Generate the help for this argument.
     *
     * @param int $width The width to make the name of the option.
     */
    string help(int $width = 0) {
        string myName = this.name;
        if (strlen(myName) < $width) {
            myName = str_pad(myName, $width, " ");
        }
        $optional = "";
        if (!this.isRequired()) {
            $optional = " <comment>(optional)</comment>";
        }
        if (_choices) {
            $optional .= sprintf(" <comment>(choices: %s)</comment>", implode("|", _choices));
        }

        return sprintf("%s%s%s", myName, _help, $optional);
    }

    // Get the usage value for this argument
    string usage() {
        string myName = name;
        if (_choices) {
            myName = implode("|", _choices);
        }
        myName = "<" . myName . ">";
        if (!this.isRequired()) {
            myName = "[" . myName . "]";
        }

        return myName;
    }

    /**
     * Check if this argument is a required argument
    bool isRequired() {
        return _required;
    }

    /**
     * Check that myValue is a valid choice for this argument.
     *
     * @param string myValue The choice to validate.
     * @return true
     * @throws uim.cake.Console\Exception\ConsoleException
     */
    bool validChoice(string myValue) {
        if (empty(_choices)) {
            return true;
        }
        if (!in_array(myValue, _choices, true)) {
            throw new ConsoleException(
                sprintf(
                    ""%s" is not a valid value for %s. Please use one of "%s"",
                    myValue,
                    name,
                    implode(", ", _choices)
                )
            );
        }

        return true;
    }

    /**
     * Append this arguments XML representation to the passed in SimpleXml object.
     *
     * @param \SimpleXMLElement $parent The parent element.
     * @return \SimpleXMLElement The parent with this argument appended.
     */
    function xml(SimpleXMLElement $parent): SimpleXMLElement
    {
        $option = $parent.addChild("argument");
        $option.addAttribute("name", name);
        $option.addAttribute("help", _help);
        $option.addAttribute("required", (string)(int)this.isRequired());
        $choices = $option.addChild("choices");
        foreach ($valid; _choices) {
            $choices.addChild("choice", $valid);
        }

        return $parent;
    }
}
