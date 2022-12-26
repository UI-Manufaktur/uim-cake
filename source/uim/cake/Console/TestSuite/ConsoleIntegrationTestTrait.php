

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.7.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.consoles.TestSuite;

import uim.cake.Command\Command;
import uim.cake.consoles.CommandRunner;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.Exception\StopException;
import uim.cake.consoles.TestSuite\Constraint\ContentsContain;
import uim.cake.consoles.TestSuite\Constraint\ContentsContainRow;
import uim.cake.consoles.TestSuite\Constraint\ContentsEmpty;
import uim.cake.consoles.TestSuite\Constraint\ContentsNotContain;
import uim.cake.consoles.TestSuite\Constraint\ContentsRegExp;
import uim.cake.consoles.TestSuite\Constraint\ExitCode;
import uim.cake.cores.TestSuite\ContainerStubTrait;
use RuntimeException;

/**
 * A bundle of methods that makes testing commands
 * and shell classes easier.
 *
 * Enables you to call commands/shells with a
 * full application context.
 */
trait ConsoleIntegrationTestTrait
{
    use ContainerStubTrait;

    /**
     * Whether to use the CommandRunner
     *
     * @var bool
     */
    protected $_useCommandRunner = false;

    /**
     * Last exit code
     *
     * @var int|null
     */
    protected $_exitCode;

    /**
     * Console output stub
     *
     * @var \Cake\Console\TestSuite\StubConsoleOutput
     */
    protected $_out;

    /**
     * Console error output stub
     *
     * @var \Cake\Console\TestSuite\StubConsoleOutput
     */
    protected $_err;

    /**
     * Console input mock
     *
     * @var \Cake\Console\TestSuite\StubConsoleInput
     */
    protected $_in;

    /**
     * Runs CLI integration test
     *
     * @param string $command Command to run
     * @param array $input Input values to pass to an interactive shell
     * @throws \Cake\Console\TestSuite\MissingConsoleInputException
     * @throws \RuntimeException
     * @return void
     */
    function exec(string $command, array $input = []): void
    {
        $runner = this.makeRunner();

        if (_out == null) {
            _out = new StubConsoleOutput();
        }
        if (_err == null) {
            _err = new StubConsoleOutput();
        }
        if (_in == null) {
            _in = new StubConsoleInput($input);
        } elseif ($input) {
            throw new RuntimeException("You can use `$input` only if `$_in` property is null and will be reset.");
        }

        $args = this.commandStringToArgs("cake $command");
        $io = new ConsoleIo(_out, _err, _in);

        try {
            _exitCode = $runner.run($args, $io);
        } catch (MissingConsoleInputException $e) {
            $messages = _out.messages();
            if (count($messages)) {
                $e.setQuestion($messages[count($messages) - 1]);
            }
            throw $e;
        } catch (StopException $exception) {
            _exitCode = $exception.getCode();
        }
    }

    /**
     * Cleans state to get ready for the next test
     *
     * @after
     * @return void
     * @psalm-suppress PossiblyNullPropertyAssignmentValue
     */
    function cleanupConsoleTrait(): void
    {
        _exitCode = null;
        _out = null;
        _err = null;
        _in = null;
        _useCommandRunner = false;
    }

    /**
     * Set this test case to use the CommandRunner rather than the legacy
     * ShellDispatcher
     *
     * @return void
     */
    function useCommandRunner(): void
    {
        _useCommandRunner = true;
    }

    /**
     * Asserts shell exited with the expected code
     *
     * @param int $expected Expected exit code
     * @param string $message Failure message
     * @return void
     */
    function assertExitCode(int $expected, string $message = ""): void
    {
        this.assertThat($expected, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts shell exited with the Command::CODE_SUCCESS
     *
     * @param string $message Failure message
     * @return void
     */
    function assertExitSuccess($message = "")
    {
        this.assertThat(Command::CODE_SUCCESS, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts shell exited with Command::CODE_ERROR
     *
     * @param string $message Failure message
     * @return void
     */
    function assertExitError($message = "")
    {
        this.assertThat(Command::CODE_ERROR, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts that `stdout` is empty
     *
     * @param string $message The message to output when the assertion fails.
     * @return void
     */
    function assertOutputEmpty(string $message = ""): void
    {
        this.assertThat(null, new ContentsEmpty(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` contains expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     * @return void
     */
    function assertOutputContains(string $expected, string $message = ""): void
    {
        this.assertThat($expected, new ContentsContain(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` does not contain expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     * @return void
     */
    function assertOutputNotContains(string $expected, string $message = ""): void
    {
        this.assertThat($expected, new ContentsNotContain(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string $message Failure message
     * @return void
     */
    function assertOutputRegExp(string $pattern, string $message = ""): void
    {
        this.assertThat($pattern, new ContentsRegExp(_out.messages(), "output"), $message);
    }

    /**
     * Check that a row of cells exists in the output.
     *
     * @param array $row Row of cells to ensure exist in the output.
     * @param string $message Failure message.
     * @return void
     */
    protected function assertOutputContainsRow(array $row, string $message = ""): void
    {
        this.assertThat($row, new ContentsContainRow(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stderr` contains expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     * @return void
     */
    function assertErrorContains(string $expected, string $message = ""): void
    {
        this.assertThat($expected, new ContentsContain(_err.messages(), "error output"), $message);
    }

    /**
     * Asserts `stderr` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string $message Failure message
     * @return void
     */
    function assertErrorRegExp(string $pattern, string $message = ""): void
    {
        this.assertThat($pattern, new ContentsRegExp(_err.messages(), "error output"), $message);
    }

    /**
     * Asserts that `stderr` is empty
     *
     * @param string $message The message to output when the assertion fails.
     * @return void
     */
    function assertErrorEmpty(string $message = ""): void
    {
        this.assertThat(null, new ContentsEmpty(_err.messages(), "error output"), $message);
    }

    /**
     * Builds the appropriate command dispatcher
     *
     * @return \Cake\Console\CommandRunner|\Cake\Console\TestSuite\LegacyCommandRunner
     */
    protected function makeRunner()
    {
        if (_useCommandRunner) {
            /** @var \Cake\Core\IConsoleApplication $app */
            $app = this.createApp();

            return new CommandRunner($app);
        }

        return new LegacyCommandRunner();
    }

    /**
     * Creates an $argv array from a command string
     *
     * @param string $command Command string
     * @return array<string>
     */
    protected string[] commandStringToArgs(string $command): array
    {
        $charCount = strlen($command);
        $argv = [];
        $arg = "";
        $inDQuote = false;
        $inSQuote = false;
        for ($i = 0; $i < $charCount; $i++) {
            $char = substr($command, $i, 1);

            // end of argument
            if ($char == " " && !$inDQuote && !$inSQuote) {
                if ($arg != "") {
                    $argv[] = $arg;
                }
                $arg = "";
                continue;
            }

            // exiting single quote
            if ($inSQuote && $char == """) {
                $inSQuote = false;
                continue;
            }

            // exiting double quote
            if ($inDQuote && $char == """) {
                $inDQuote = false;
                continue;
            }

            // entering double quote
            if ($char == """ && !$inSQuote) {
                $inDQuote = true;
                continue;
            }

            // entering single quote
            if ($char == """ && !$inDQuote) {
                $inSQuote = true;
                continue;
            }

            $arg .= $char;
        }
        $argv[] = $arg;

        return $argv;
    }
}
