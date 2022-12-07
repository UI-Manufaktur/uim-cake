module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.Configure;

/**
 * built-in Server command
 */
class ServerCommand : Command {
    /**
     * Default ServerHost
     *
     * @var string
     */
    public const DEFAULT_HOST = "localhost";

    /**
     * Default ListenPort
    */
    public const int DEFAULT_PORT = 8765;

    /**
     * server host
     *
     * @var string
     */
    protected $_host = self::DEFAULT_HOST;

    /**
     * listen port
     *
     * @var int
     */
    protected $_port = self::DEFAULT_PORT;

    /**
     * document root
     *
     * @var string
     */
    protected $_documentRoot = WWW_ROOT;

    /**
     * ini path
     *
     * @var string
     */
    protected $_iniPath = "";

    /**
     * Starts up the Command and displays the welcome message.
     * Allows for checking and configuring prior to command or main execution
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return void
     * @link https://book.UIM.org/4/en/console-and-shells.html#hook-methods
     */
    protected void startup(Arguments $args, ConsoleIo $io) {
        if ($args.getOption("host")) {
            this._host = (string)$args.getOption("host");
        }
        if ($args.getOption("port")) {
            this._port = (int)$args.getOption("port");
        }
        if ($args.getOption("document_root")) {
            this._documentRoot = (string)$args.getOption("document_root");
        }
        if ($args.getOption("ini_path")) {
            this._iniPath = (string)$args.getOption("ini_path");
        }

        // For Windows
        if (substr(this._documentRoot, -1, 1) === DIRECTORY_SEPARATOR) {
            this._documentRoot = substr(this._documentRoot, 0, strlen(this._documentRoot) - 1);
        }
        if (preg_match("/^([a-z]:)[\\\]+(.+)$/i", this._documentRoot, $m)) {
            this._documentRoot = $m[1] . "\\" . $m[2];
        }

        this._iniPath = rtrim(this._iniPath, DIRECTORY_SEPARATOR);
        if (preg_match("/^([a-z]:)[\\\]+(.+)$/i", this._iniPath, $m)) {
            this._iniPath = $m[1] . "\\" . $m[2];
        }

        $io.out();
        $io.out(sprintf("<info>Welcome to UIM %s Console</info>", "v" . Configure::version()));
        $io.hr();
        $io.out(sprintf("App : %s", Configure::read("App.dir")));
        $io.out(sprintf("Path: %s", APP));
        $io.out(sprintf("DocumentRoot: %s", this._documentRoot));
        $io.out(sprintf("Ini Path: %s", this._iniPath));
        $io.hr();
    }

    /**
     * Execute.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    auto execute(Arguments $args, ConsoleIo $io): Nullable!int
    {
        this.startup($args, $io);
        $phpBinary = (string)env("PHP", "php");
        $command = sprintf(
            "%s -S %s:%d -t %s",
            $phpBinary,
            this._host,
            this._port,
            escapeshellarg(this._documentRoot)
        );

        if (!empty(this._iniPath)) {
            $command = sprintf("%s -c %s", $command, this._iniPath);
        }

        $command = sprintf("%s %s", $command, escapeshellarg(this._documentRoot . "/index.php"));

        $port = ":" . this._port;
        $io.out(sprintf("built-in server is running in http://%s%s/", this._host, $port));
        $io.out("You can exit with <info>`CTRL-C`</info>");
        system($command);

        return static::CODE_SUCCESS;
    }

    /**
     * Hook method for defining this command"s option parser.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription([
            "PHP Built-in Server for UIM",
            "<warning>[WARN] Don\"t use this in a production environment</warning>",
        ]).addOption("host", [
            "short":"H",
            "help":"ServerHost",
        ]).addOption("port", [
            "short":"p",
            "help":"ListenPort",
        ]).addOption("ini_path", [
            "short":"I",
            "help":"php.ini path",
        ]).addOption("document_root", [
            "short":"d",
            "help":"DocumentRoot",
        ]);

        return $parser;
    }
}
