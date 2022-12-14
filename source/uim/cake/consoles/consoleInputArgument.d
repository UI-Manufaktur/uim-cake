/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.consoles;

@safe:
import uim.cake;

import uim.cake.consoles.exceptions.ConsoleException;
use SimpleXMLElement;

/**
 * An object to represent a single argument used in the command line.
 * ConsoleOptionParser creates these when you use addArgument()
 *
 * @see uim.cake.consoles.ConsoleOptionParser::addArgument()
 */
class ConsoleInputArgument {
    // Name of the argument.
    protected string _name;

    // Help string
    protected string _help;

    // Is this option required?
    protected bool _required;

    /**
     * An array of valid choices for this argument.
     */
    protected string[] _choices;

    /**
     * Make a new Input Argument
     *
     * @param array<string, mixed>|string aName The long name of the option, or an array with all the properties.
     * @param string $help The help text for this option
     * @param bool $required Whether this argument is required. Missing required args will trigger exceptions
     * @param array<string> $choices Valid choices for this option.
     */
    this($name, $help = "", $required = false, $choices = null) {
        if (is_array($name) && isset($name["name"])) {
            foreach ($name as $key: $value) {
                this.{"_" ~ $key} = $value;
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
     * @return Value of _name.
     */
    string name() {
      return _name;
    }

    /**
     * Checks if this argument is equal to another argument.
     *
     * @param uim.cake.consoles.ConsoleInputArgument $argument ConsoleInputArgument to compare to.
     */
    bool isEqualTo(ConsoleInputArgument $argument) {
        return this.name() == $argument.name() &&
            this.usage() == $argument.usage();
    }

    /**
     * Generate the help for this argument.
     *
     * @param int $width The width to make the name of the option.
     */
    string help(int $width = 0) {
        $name = _name;
        if (strlen($name) < $width) {
            $name = str_pad($name, $width, " ");
        }
        $optional = "";
        if (!this.isRequired()) {
            $optional = " <comment>(optional)</comment>";
        }
        if (_choices) {
            $optional ~= sprintf(" <comment>(choices: %s)</comment>", implode("|", _choices));
        }

        return sprintf("%s%s%s", $name, _help, $optional);
    }

    /**
     * Get the usage value for this argument
     */
    string usage() {
        $name = _name;
        if (_choices) {
            $name = implode("|", _choices);
        }
        $name = "<" ~ $name ~ ">";
        if (!this.isRequired()) {
            $name = "[" ~ $name ~ "]";
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
     * @param string aValue The choice to validate.
     * @return true
     * @throws uim.cake.consoles.exceptions.ConsoleException
     */
    bool validChoice(string aValue) {
        if (empty(_choices)) {
            return true;
        }
        if (!hasAllValues($value, _choices, true)) {
            throw new ConsoleException(
                sprintf(
                    "'%s' is not a valid value for %s. Please use one of '%s'",
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
