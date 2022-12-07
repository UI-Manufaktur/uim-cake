module uim.cake.console;

import uim.cake.console.exceptions\ConsoleException;
use SimpleXMLElement;

/**
 * An object to represent a single argument used in the command line.
 * ConsoleOptionParser creates these when you use addArgument()
 *
 * @see \Cake\Console\ConsoleOptionParser::addArgument()
 */
class ConsoleInputArgument
{
    /**
     * Name of the argument.
     *
     * @var string
     */
    protected $_name;

    /**
     * Help string
     *
     * @var string
     */
    protected $_help;

    /**
     * Is this option required?
     *
     * @var bool
     */
    protected $_required;

    /**
     * An array of valid choices for this argument.
     *
     * @var array<string>
     */
    protected $_choices;

    /**
     * Make a new Input Argument
     *
     * @param array<string, mixed>|string myName The long name of the option, or an array with all the properties.
     * @param string $help The help text for this option
     * @param bool $required Whether this argument is required. Missing required args will trigger exceptions
     * @param array<string> $choices Valid choices for this option.
     */
    this(myName, $help = "", $required = false, $choices = []) {
        if (is_array(myName) && isset(myName["name"])) {
            foreach (myName as myKey: myValue) {
                this.{"_" . myKey} = myValue;
            }
        } else {
            /** @psalm-suppress PossiblyInvalidPropertyAssignmentValue */
            this._name = myName;
            this._help = $help;
            this._required = $required;
            this._choices = $choices;
        }
    }

    /**
     * Get the value of the name attribute.
     *
     * @return string Value of this._name.
     */
    string name() {
        return this._name;
    }

    /**
     * Checks if this argument is equal to another argument.
     *
     * @param \Cake\Console\ConsoleInputArgument $argument ConsoleInputArgument to compare to.
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
        myName = this._name;
        if (strlen(myName) < $width) {
            myName = str_pad(myName, $width, " ");
        }
        $optional = "";
        if (!this.isRequired()) {
            $optional = " <comment>(optional)</comment>";
        }
        if (this._choices) {
            $optional .= sprintf(" <comment>(choices: %s)</comment>", implode("|", this._choices));
        }

        return sprintf("%s%s%s", myName, this._help, $optional);
    }

    /**
     * Get the usage value for this argument
     */
    string usage() {
        myName = this._name;
        if (this._choices) {
            myName = implode("|", this._choices);
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
        return this._required;
    }

    /**
     * Check that myValue is a valid choice for this argument.
     *
     * @param string myValue The choice to validate.
     * @return true
     * @throws \Cake\Console\Exception\ConsoleException
     */
    bool validChoice(string myValue) {
        if (empty(this._choices)) {
            return true;
        }
        if (!in_array(myValue, this._choices, true)) {
            throw new ConsoleException(
                sprintf(
                    ""%s" is not a valid value for %s. Please use one of "%s"",
                    myValue,
                    this._name,
                    implode(", ", this._choices)
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
        $option.addAttribute("name", this._name);
        $option.addAttribute("help", this._help);
        $option.addAttribute("required", (string)(int)this.isRequired());
        $choices = $option.addChild("choices");
        foreach (this._choices as $valid) {
            $choices.addChild("choice", $valid);
        }

        return $parent;
    }
}
