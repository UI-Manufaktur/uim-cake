


 *


 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

import uim.cake.utilities.Text;
use SimpleXMLElement;

/**
 * HelpFormatter formats help for console shells. Can format to either
 * text or XML formats. Uses ConsoleOptionParser methods to generate help.
 *
 * Generally not directly used. Using $parser.help($command, "xml"); is usually
 * how you would access help. Or via the `--help=xml` option on the command line.
 *
 * Xml output is useful for integration with other tools like IDE"s or other build tools.
 */
class HelpFormatter
{
    /**
     * The maximum number of arguments shown when generating usage.
     *
     * @var int
     */
    protected $_maxArgs = 6;

    /**
     * The maximum number of options shown when generating usage.
     *
     * @var int
     */
    protected $_maxOptions = 6;

    /**
     * Option parser.
     *
     * @var \Cake\Console\ConsoleOptionParser
     */
    protected $_parser;

    /**
     * Alias to display in the output.
     *
     * @var string
     */
    protected $_alias = "cake";

    /**
     * Build the help formatter for an OptionParser
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser help is being generated for.
     */
    public this(ConsoleOptionParser $parser) {
        _parser = $parser;
    }

    /**
     * Set the alias
     *
     * @param string $alias The alias
     * @return void
     */
    function setAlias(string $alias): void
    {
        _alias = $alias;
    }

    /**
     * Get the help as formatted text suitable for output on the command line.
     *
     * @param int $width The width of the help output.
     * @return string
     */
    function text(int $width = 72): string
    {
        $parser = _parser;
        $out = [];
        $description = $parser.getDescription();
        if (!empty($description)) {
            $out[] = Text::wrap($description, $width);
            $out[] = "";
        }
        $out[] = "<info>Usage:</info>";
        $out[] = _generateUsage();
        $out[] = "";
        $subcommands = $parser.subcommands();
        if (!empty($subcommands)) {
            $out[] = "<info>Subcommands:</info>";
            $out[] = "";
            $max = _getMaxLength($subcommands) + 2;
            foreach ($subcommands as $command) {
                $out[] = Text::wrapBlock($command.help($max), [
                    "width": $width,
                    "indent": str_repeat(" ", $max),
                    "indentAt": 1,
                ]);
            }
            $out[] = "";
            $out[] = sprintf(
                "To see help on a subcommand use <info>`" . _alias . " %s [subcommand] --help`</info>",
                $parser.getCommand()
            );
            $out[] = "";
        }

        $options = $parser.options();
        if ($options) {
            $max = _getMaxLength($options) + 8;
            $out[] = "<info>Options:</info>";
            $out[] = "";
            foreach ($options as $option) {
                $out[] = Text::wrapBlock($option.help($max), [
                    "width": $width,
                    "indent": str_repeat(" ", $max),
                    "indentAt": 1,
                ]);
            }
            $out[] = "";
        }

        $arguments = $parser.arguments();
        if (!empty($arguments)) {
            $max = _getMaxLength($arguments) + 2;
            $out[] = "<info>Arguments:</info>";
            $out[] = "";
            foreach ($arguments as $argument) {
                $out[] = Text::wrapBlock($argument.help($max), [
                    "width": $width,
                    "indent": str_repeat(" ", $max),
                    "indentAt": 1,
                ]);
            }
            $out[] = "";
        }
        $epilog = $parser.getEpilog();
        if (!empty($epilog)) {
            $out[] = Text::wrap($epilog, $width);
            $out[] = "";
        }

        return implode("\n", $out);
    }

    /**
     * Generate the usage for a shell based on its arguments and options.
     * Usage strings favor short options over the long ones. and optional args will
     * be indicated with []
     *
     * @return string
     */
    protected function _generateUsage(): string
    {
        $usage = [_alias . " " . _parser.getCommand()];
        $subcommands = _parser.subcommands();
        if (!empty($subcommands)) {
            $usage[] = "[subcommand]";
        }
        $options = [];
        foreach (_parser.options() as $option) {
            $options[] = $option.usage();
        }
        if (count($options) > _maxOptions) {
            $options = ["[options]"];
        }
        $usage = array_merge($usage, $options);
        $args = [];
        foreach (_parser.arguments() as $argument) {
            $args[] = $argument.usage();
        }
        if (count($args) > _maxArgs) {
            $args = ["[arguments]"];
        }
        $usage = array_merge($usage, $args);

        return implode(" ", $usage);
    }

    /**
     * Iterate over a collection and find the longest named thing.
     *
     * @param array<\Cake\Console\ConsoleInputOption|\Cake\Console\ConsoleInputArgument|\Cake\Console\ConsoleInputSubcommand> $collection The collection to find a max length of.
     * @return int
     */
    protected function _getMaxLength(array $collection): int
    {
        $max = 0;
        foreach ($collection as $item) {
            $max = strlen($item.name()) > $max ? strlen($item.name()) : $max;
        }

        return $max;
    }

    /**
     * Get the help as an XML string.
     *
     * @param bool $string Return the SimpleXml object or a string. Defaults to true.
     * @return \SimpleXMLElement|string See $string
     */
    function xml(bool $string = true) {
        $parser = _parser;
        $xml = new SimpleXMLElement("<shell></shell>");
        $xml.addChild("command", $parser.getCommand());
        $xml.addChild("description", $parser.getDescription());

        $subcommands = $xml.addChild("subcommands");
        foreach ($parser.subcommands() as $command) {
            $command.xml($subcommands);
        }
        $options = $xml.addChild("options");
        foreach ($parser.options() as $option) {
            $option.xml($options);
        }
        $arguments = $xml.addChild("arguments");
        foreach ($parser.arguments() as $argument) {
            $argument.xml($arguments);
        }
        $xml.addChild("epilog", $parser.getEpilog());

        return $string ? (string)$xml.asXML() : $xml;
    }
}
