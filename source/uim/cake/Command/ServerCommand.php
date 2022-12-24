

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */

module uim.cake.Command;

import uim.cake.Console\Arguments;
import uim.cake.Console\ConsoleIo;
import uim.cake.Console\ConsoleOptionParser;
import uim.cake.Core\Configure;

/**
 * built-in Server command
 */
class ServerCommand : Command
{
    /**
     * Default ServerHost
     *
     * @var string
     */
    public const DEFAULT_HOST = "localhost";

    /**
     * Default ListenPort
     *
     * @var int
     */
    public const DEFAULT_PORT = 8765;

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
     * @link https://book.cakephp.org/4/en/console-and-shells.html#hook-methods
     */
    protected function startup(Arguments $args, ConsoleIo $io): void
    {
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
        $io.out(sprintf("<info>Welcome to CakePHP %s Console</info>", "v" . Configure::version()));
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
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
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
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription([
            "PHP Built-in Server for CakePHP",
            "<warning>[WARN] Don\"t use this in a production environment</warning>",
        ]).addOption("host", [
            "short": "H",
            "help": "ServerHost",
        ]).addOption("port", [
            "short": "p",
            "help": "ListenPort",
        ]).addOption("ini_path", [
            "short": "I",
            "help": "php.ini path",
        ]).addOption("document_root", [
            "short": "d",
            "help": "DocumentRoot",
        ]);

        return $parser;
    }
}
