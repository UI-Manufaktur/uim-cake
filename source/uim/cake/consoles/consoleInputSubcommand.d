/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.console;

@safe:
import uim.cake;

/**
 * An object to represent a single subcommand used in the command line.
 * Created when you call ConsoleOptionParser::addSubcommand()
 *
 * @see uim.cake.consoles.ConsoleOptionParser::addSubcommand()
 */
class ConsoleInputSubCommand {
    // Name of the subcommand
    protected string _name = "";

    /**
     * Help string for the subcommand
     */
    protected string _help = "";

    /**
     * The ConsoleOptionParser for this subcommand.
     *
     * @var uim.cake.consoles.ConsoleOptionParser|null
     */
    protected _parser;

    /**
     * Make a new Subcommand
     *
     * @param array<string, mixed>|string myName The long name of the subcommand, or an array with all the properties.
     * @param string help The help text for this option.
     * @param uim.cake.consoles.ConsoleOptionParser|array<string, mixed>|null $parser A parser for this subcommand.
     *   Either a ConsoleOptionParser, or an array that can be used with ConsoleOptionParser::buildFromArray().
     */
    this(myName, $help = "", $parser = null) {
        if (is_array(myName)) {
            myData = myName + ["name":null, "help":"", "parser":null];
            if (empty(myData["name"])) {
                throw new InvalidArgumentException(""name" not provided for console option parser");
            }

            myName = myData["name"];
            $help = myData["help"];
            $parser = myData["parser"];
        }

        if (is_array($parser)) {
            $parser["command"] = myName;
            $parser = ConsoleOptionParser::buildFromArray($parser);
        }

        _name = myName;
        _help = $help;
        _parser = $parser;
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
     * Get the raw help string for this command
     */
    string getRawHelp() {
        return _help;
    }

    /**
     * Generate the help for this this subcommand.
     *
     * @param int $width The width to make the name of the subcommand.
     */
    string help(int $width = 0) {
        myName = _name;
        if (strlen(myName) < $width) {
            myName = str_pad(myName, $width, " ");
        }

        return myName . _help;
    }

    /**
     * Get the usage value for this option
     *
     * @return uim.cake.consoles.ConsoleOptionParser|null
     */
    ?ConsoleOptionParser parser() {
        return _parser;
    }

    /**
     * Append this subcommand to the Parent element
     *
     * @param \SimpleXMLElement $parent The parent element.
     * @return \SimpleXMLElement The parent with this subcommand appended.
     */
    SimpleXMLElement xml(SimpleXMLElement $parent) {
        $command = $parent.addChild("command");
        $command.addAttribute("name", _name);
        $command.addAttribute("help", _help);

        return $parent;
    }
}
