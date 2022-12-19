module uim.cake.command;

import uim.cake.console.Arguments;
import uim.cake.console.consoleIo;
import uim.cake.console.consoleOptionParser;
import uim.cake.core.Configure;

/**
 * built-in Server command
 */
class ServerCommand : Command {
    // Default ServerHost
    public const string DEFAULT_HOST = "localhost";

    // Default ListenPort
    public const int DEFAULT_PORT = 8765;

    // server host
    protected string _host = self::DEFAULT_HOST;

    /**
     * listen port
     *
     * @var int
     */
    protected _port = self::DEFAULT_PORT;

    // document root
    protected string _documentRoot = WWW_ROOT;

    // ini path
    protected string _iniPath = "";

    /**
     * Starts up the Command and displays the welcome message.
     * Allows for checking and configuring prior to command or main execution
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @link https://book.UIM.org/4/en/console-and-shells.html#hook-methods
     */
    protected void startup(Arguments $args, ConsoleIo $io) {
        if ($args.getOption("host")) {
            _host = (string)$args.getOption("host");
        }
        if ($args.getOption("port")) {
            _port = (int)$args.getOption("port");
        }
        if ($args.getOption("document_root")) {
            _documentRoot = (string)$args.getOption("document_root");
        }
        if ($args.getOption("ini_path")) {
            _iniPath = (string)$args.getOption("ini_path");
        }

        // For Windows
        if (substr(_documentRoot, -1, 1) == DIRECTORY_SEPARATOR) {
            _documentRoot = substr(_documentRoot, 0, strlen(_documentRoot) - 1);
        }
        if (preg_match("/^([a-z]:)[\\\]+(.+)$/i", _documentRoot, $m)) {
            _documentRoot = $m[1] . "\\" . $m[2];
        }

        _iniPath = rtrim(_iniPath, DIRECTORY_SEPARATOR);
        if (preg_match("/^([a-z]:)[\\\]+(.+)$/i", _iniPath, $m)) {
            _iniPath = $m[1] . "\\" . $m[2];
        }

        $io.out();
        $io.out(sprintf("<info>Welcome to UIM %s Console</info>", "v" . Configure::version()));
        $io.hr();
        $io.out(sprintf("App : %s", Configure::read("App.dir")));
        $io.out(sprintf("Path: %s", APP));
        $io.out(sprintf("DocumentRoot: %s", _documentRoot));
        $io.out(sprintf("Ini Path: %s", _iniPath));
        $io.hr();
    }

    /**
     * Execute.
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    Nullable!int execute(Arguments $args, ConsoleIo $io) {
      this.startup($args, $io);
      $phpBinary = (string)env("PHP", "php");
      $command = sprintf(
        "%s -S %s:%d -t %s",
        $phpBinary,
        _host,
        _port,
        escapeshellarg(_documentRoot)
      );

      if (!empty(_iniPath)) {
        $command = sprintf("%s -c %s", $command, _iniPath);
      }

      $command = sprintf("%s %s", $command, escapeshellarg(_documentRoot . "/index.php"));

      $port = ":" . _port;
      $io.out(sprintf("built-in server is running in http://%s%s/", _host, $port));
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
    ConsoleOptionParser buildOptionParser(ConsoleOptionParser $parser) {
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
