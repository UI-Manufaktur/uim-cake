

/**
 * ConsoleInputSubcommand file
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         2.0.0
  */
module uim.cake.Console;

use InvalidArgumentException;
use SimpleXMLElement;

/**
 * An object to represent a single subcommand used in the command line.
 * Created when you call ConsoleOptionParser::addSubcommand()
 *
 * @see uim.cake.consoles.ConsoleOptionParser::addSubcommand()
 */
class ConsoleInputSubcommand
{
    /**
     * Name of the subcommand
     *
     * @var string
     */
    protected $_name = "";

    /**
     * Help string for the subcommand
     *
     * @var string
     */
    protected $_help = "";

    /**
     * The ConsoleOptionParser for this subcommand.
     *
     * @var uim.cake.consoles.ConsoleOptionParser|null
     */
    protected $_parser;

    /**
     * Make a new Subcommand
     *
     * @param array<string, mixed>|string $name The long name of the subcommand, or an array with all the properties.
     * @param string $help The help text for this option.
     * @param uim.cake.consoles.ConsoleOptionParser|array<string, mixed>|null $parser A parser for this subcommand.
     *   Either a ConsoleOptionParser, or an array that can be used with ConsoleOptionParser::buildFromArray().
     */
    this($name, $help = "", $parser = null) {
        if (is_array($name)) {
            $data = $name + ["name": null, "help": "", "parser": null];
            if (empty($data["name"])) {
                throw new InvalidArgumentException(""name" not provided for console option parser");
            }

            $name = $data["name"];
            $help = $data["help"];
            $parser = $data["parser"];
        }

        if (is_array($parser)) {
            $parser["command"] = $name;
            $parser = ConsoleOptionParser::buildFromArray($parser);
        }

        _name = $name;
        _help = $help;
        _parser = $parser;
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
     * Get the raw help string for this command
     *
     * @return string
     */
    string getRawHelp(): string
    {
        return _help;
    }

    /**
     * Generate the help for this this subcommand.
     *
     * @param int $width The width to make the name of the subcommand.
     * @return string
     */
    string help(int $width = 0): string
    {
        $name = _name;
        if (strlen($name) < $width) {
            $name = str_pad($name, $width, " ");
        }

        return $name . _help;
    }

    /**
     * Get the usage value for this option
     *
     * @return uim.cake.consoles.ConsoleOptionParser|null
     */
    function parser(): ?ConsoleOptionParser
    {
        return _parser;
    }

    /**
     * Append this subcommand to the Parent element
     *
     * @param \SimpleXMLElement $parent The parent element.
     * @return \SimpleXMLElement The parent with this subcommand appended.
     */
    function xml(SimpleXMLElement $parent): SimpleXMLElement
    {
        $command = $parent.addChild("command");
        $command.addAttribute("name", _name);
        $command.addAttribute("help", _help);

        return $parent;
    }
}
