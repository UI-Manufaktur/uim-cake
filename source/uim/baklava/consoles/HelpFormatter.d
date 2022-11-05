module uim.baklava.console;

import uim.baklava.utikities.Text;
use SimpleXMLElement;

/**
 * HelpFormatter formats help for console shells. Can format to either
 * text or XML formats. Uses ConsoleOptionParser methods to generate help.
 *
 * Generally not directly used. Using $parser.help($command, 'xml'); is usually
 * how you would access help. Or via the `--help=xml` option on the command line.
 *
 * Xml output is useful for integration with other tools like IDE's or other build tools.
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
    protected $_alias = 'cake';

    /**
     * Build the help formatter for an OptionParser
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser help is being generated for.
     */
    this(ConsoleOptionParser $parser) {
        this._parser = $parser;
    }

    /**
     * Set the alias
     *
     * @param string myAlias The alias
     * @return void
     */
    void setAlias(string myAlias) {
        this._alias = myAlias;
    }

    /**
     * Get the help as formatted text suitable for output on the command line.
     *
     * @param int $width The width of the help output.
     */
    string text(int $width = 72) {
        $parser = this._parser;
        $out = [];
        $description = $parser.getDescription();
        if (!empty($description)) {
            $out[] = Text::wrap($description, $width);
            $out[] = '';
        }
        $out[] = '<info>Usage:</info>';
        $out[] = this._generateUsage();
        $out[] = '';
        $subcommands = $parser.subcommands();
        if (!empty($subcommands)) {
            $out[] = '<info>Subcommands:</info>';
            $out[] = '';
            $max = this._getMaxLength($subcommands) + 2;
            foreach ($subcommands as $command) {
                $out[] = Text::wrapBlock($command.help($max), [
                    'width' => $width,
                    'indent' => str_repeat(' ', $max),
                    'indentAt' => 1,
                ]);
            }
            $out[] = '';
            $out[] = sprintf(
                'To see help on a subcommand use <info>`' . this._alias . ' %s [subcommand] --help`</info>',
                $parser.getCommand()
            );
            $out[] = '';
        }

        myOptions = $parser.options();
        if (myOptions) {
            $max = this._getMaxLength(myOptions) + 8;
            $out[] = '<info>Options:</info>';
            $out[] = '';
            foreach (myOptions as $option) {
                $out[] = Text::wrapBlock($option.help($max), [
                    'width' => $width,
                    'indent' => str_repeat(' ', $max),
                    'indentAt' => 1,
                ]);
            }
            $out[] = '';
        }

        $arguments = $parser.arguments();
        if (!empty($arguments)) {
            $max = this._getMaxLength($arguments) + 2;
            $out[] = '<info>Arguments:</info>';
            $out[] = '';
            foreach ($arguments as $argument) {
                $out[] = Text::wrapBlock($argument.help($max), [
                    'width' => $width,
                    'indent' => str_repeat(' ', $max),
                    'indentAt' => 1,
                ]);
            }
            $out[] = '';
        }
        $epilog = $parser.getEpilog();
        if (!empty($epilog)) {
            $out[] = Text::wrap($epilog, $width);
            $out[] = '';
        }

        return implode("\n", $out);
    }

    /**
     * Generate the usage for a shell based on its arguments and options.
     * Usage strings favor short options over the long ones. and optional args will
     * be indicated with []
     */
    protected string _generateUsage() {
        $usage = [this._alias . ' ' . this._parser.getCommand()];
        $subcommands = this._parser.subcommands();
        if (!empty($subcommands)) {
            $usage[] = '[subcommand]';
        }
        myOptions = [];
        foreach (this._parser.options() as $option) {
            myOptions[] = $option.usage();
        }
        if (count(myOptions) > this._maxOptions) {
            myOptions = ['[options]'];
        }
        $usage = array_merge($usage, myOptions);
        $args = [];
        foreach (this._parser.arguments() as $argument) {
            $args[] = $argument.usage();
        }
        if (count($args) > this._maxArgs) {
            $args = ['[arguments]'];
        }
        $usage = array_merge($usage, $args);

        return implode(' ', $usage);
    }

    /**
     * Iterate over a collection and find the longest named thing.
     *
     * @param array<\Cake\Console\ConsoleInputOption|\Cake\Console\ConsoleInputArgument|\Cake\Console\ConsoleInputSubcommand> myCollection The collection to find a max length of.
     * @return int
     */
    protected auto _getMaxLength(array myCollection): int
    {
        $max = 0;
        foreach (myCollection as $item) {
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
        $parser = this._parser;
        $xml = new SimpleXMLElement('<shell></shell>');
        $xml.addChild('command', $parser.getCommand());
        $xml.addChild('description', $parser.getDescription());

        $subcommands = $xml.addChild('subcommands');
        foreach ($parser.subcommands() as $command) {
            $command.xml($subcommands);
        }
        myOptions = $xml.addChild('options');
        foreach ($parser.options() as $option) {
            $option.xml(myOptions);
        }
        $arguments = $xml.addChild('arguments');
        foreach ($parser.arguments() as $argument) {
            $argument.xml($arguments);
        }
        $xml.addChild('epilog', $parser.getEpilog());

        return $string ? (string)$xml.asXML() : $xml;
    }
}
