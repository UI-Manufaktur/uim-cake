


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

import uim.cake.consoles.exceptions.ConsoleException;
use SimpleXMLElement;

/**
 * An object to represent a single argument used in the command line.
 * ConsoleOptionParser creates these when you use addArgument()
 *
 * @see uim.cake.Console\ConsoleOptionParser::addArgument()
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
    protected string[] $_choices;

    /**
     * Make a new Input Argument
     *
     * @param array<string, mixed>|string $name The long name of the option, or an array with all the properties.
     * @param string $help The help text for this option
     * @param bool $required Whether this argument is required. Missing required args will trigger exceptions
     * @param array<string> $choices Valid choices for this option.
     */
    public this($name, $help = "", $required = false, $choices = []) {
        if (is_array($name) && isset($name["name"])) {
            foreach ($name as $key: $value) {
                this.{"_" . $key} = $value;
            }
        } else {
            /** @psalm-suppress PossiblyInvalidPropertyAssignmentValue */
            _name = $name;
            _help = $help;
            _required = $required;
            _choices = $choices;
        }
    }

    /**
     * Get the value of the name attribute.
     *
     * @return string Value of _name.
     */
    function name(): string
    {
        return _name;
    }

    /**
     * Checks if this argument is equal to another argument.
     *
     * @param \Cake\Console\ConsoleInputArgument $argument ConsoleInputArgument to compare to.
     * @return bool
     */
    bool isEqualTo(ConsoleInputArgument $argument) {
        return this.name() == $argument.name() &&
            this.usage() == $argument.usage();
    }

    /**
     * Generate the help for this argument.
     *
     * @param int $width The width to make the name of the option.
     * @return string
     */
    bool help(int $width = 0): string
    {
        $name = _name;
        if (strlen($name) < $width) {
            $name = str_pad($name, $width, " ");
        }
        $optional = "";
        if (!this.isRequired()) {
            $optional = " <comment>(optional)</comment>";
        }
        if (_choices) {
            $optional .= sprintf(" <comment>(choices: %s)</comment>", implode("|", _choices));
        }

        return sprintf("%s%s%s", $name, _help, $optional);
    }

    /**
     * Get the usage value for this argument
     *
     * @return string
     */
    function usage(): string
    {
        $name = _name;
        if (_choices) {
            $name = implode("|", _choices);
        }
        $name = "<" . $name . ">";
        if (!this.isRequired()) {
            $name = "[" . $name . "]";
        }

        return $name;
    }

    /**
     * Check if this argument is a required argument
     *
     * @return bool
     */
    bool isRequired() {
        return _required;
    }

    /**
     * Check that $value is a valid choice for this argument.
     *
     * @param string $value The choice to validate.
     * @return true
     * @throws \Cake\Console\Exception\ConsoleException
     */
    bool validChoice(string $value) {
        if (empty(_choices)) {
            return true;
        }
        if (!in_array($value, _choices, true)) {
            throw new ConsoleException(
                sprintf(
                    ""%s" is not a valid value for %s. Please use one of "%s"",
                    $value,
                    _name,
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
        $option.addAttribute("name", _name);
        $option.addAttribute("help", _help);
        $option.addAttribute("required", (string)(int)this.isRequired());
        $choices = $option.addChild("choices");
        foreach (_choices as $valid) {
            $choices.addChild("choice", $valid);
        }

        return $parent;
    }
}
