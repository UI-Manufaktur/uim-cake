

/**
 * ConsoleInputSubcommand file
 *

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.console;

use InvalidArgumentException;
use SimpleXMLElement;

/**
 * An object to represent a single subcommand used in the command line.
 * Created when you call ConsoleOptionParser::addSubcommand()
 *
 * @see \Cake\Console\ConsoleOptionParser::addSubcommand()
 */
class ConsoleInputSubCommand {
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
     * @var \Cake\Console\ConsoleOptionParser|null
     */
    protected $_parser;

    /**
     * Make a new Subcommand
     *
     * @param array<string, mixed>|string myName The long name of the subcommand, or an array with all the properties.
     * @param string $help The help text for this option.
     * @param \Cake\Console\ConsoleOptionParser|array<string, mixed>|null $parser A parser for this subcommand.
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

        this._name = myName;
        this._help = $help;
        this._parser = $parser;
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
     * Get the raw help string for this command
     */
    string getRawHelp() {
        return this._help;
    }

    /**
     * Generate the help for this this subcommand.
     *
     * @param int $width The width to make the name of the subcommand.
     */
    string help(int $width = 0) {
        myName = this._name;
        if (strlen(myName) < $width) {
            myName = str_pad(myName, $width, " ");
        }

        return myName . this._help;
    }

    /**
     * Get the usage value for this option
     *
     * @return \Cake\Console\ConsoleOptionParser|null
     */
    function parser(): ?ConsoleOptionParser
    {
        return this._parser;
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
        $command.addAttribute("name", this._name);
        $command.addAttribute("help", this._help);

        return $parent;
    }
}
