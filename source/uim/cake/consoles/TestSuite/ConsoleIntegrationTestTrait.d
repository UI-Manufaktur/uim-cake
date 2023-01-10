module uim.cake.consoles.TestSuite;

import uim.cake.Command\Command;
import uim.cake.consoles.CommandRunner;
import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.exceptions.StopException;
import uim.cake.consoles.TestSuite\Constraint\ContentsContain;
import uim.cake.consoles.TestSuite\Constraint\ContentsContainRow;
import uim.cake.consoles.TestSuite\Constraint\ContentsEmpty;
import uim.cake.consoles.TestSuite\Constraint\ContentsNotContain;
import uim.cake.consoles.TestSuite\Constraint\ContentsRegExp;
import uim.cake.consoles.TestSuite\Constraint\ExitCode;
import uim.cake.core.TestSuite\ContainerStubTrait;
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
     */
    protected bool _useCommandRunner = false;

    /**
     * Last exit code
     *
     * @var int|null
     */
    protected _exitCode;

    /**
     * Console output stub
     *
     * @var uim.cake.consoles.TestSuite\StubConsoleOutput
     */
    protected _out;

    /**
     * Console error output stub
     *
     * @var uim.cake.consoles.TestSuite\StubConsoleOutput
     */
    protected _err;

    /**
     * Console input mock
     *
     * @var uim.cake.consoles.TestSuite\StubConsoleInput
     */
    protected _in;

    /**
     * Runs CLI integration test
     *
     * @param string $command Command to run
     * @param array $input Input values to pass to an interactive shell
     * @throws uim.cake.consoles.TestSuite\MissingConsoleInputException
     * @throws \RuntimeException
     */
    void exec(string $command, array $input = null) {
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
            throw new RuntimeException("You can use `$input` only if `_in` property is null and will be reset.");
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
    void cleanupConsoleTrait() {
        _exitCode = null;
        _out = null;
        _err = null;
        _in = null;
        _useCommandRunner = false;
    }

    /**
     * Set this test case to use the CommandRunner rather than the legacy
     * ShellDispatcher
     */
    void useCommandRunner() {
        _useCommandRunner = true;
    }

    /**
     * Asserts shell exited with the expected code
     *
     * @param int $expected Expected exit code
     * @param string $message Failure message
     */
    void assertExitCode(int $expected, string $message = "") {
        this.assertThat($expected, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts shell exited with the Command::CODE_SUCCESS
     *
     * @param string $message Failure message
     */
    void assertExitSuccess($message = "") {
        this.assertThat(Command::CODE_SUCCESS, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts shell exited with Command::CODE_ERROR
     *
     * @param string $message Failure message
     */
    void assertExitError($message = "") {
        this.assertThat(Command::CODE_ERROR, new ExitCode(_exitCode), $message);
    }

    /**
     * Asserts that `stdout` is empty
     *
     * @param string $message The message to output when the assertion fails.
     */
    void assertOutputEmpty(string $message = "") {
        this.assertThat(null, new ContentsEmpty(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` contains expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     */
    void assertOutputContains(string $expected, string $message = "") {
        this.assertThat($expected, new ContentsContain(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` does not contain expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     */
    void assertOutputNotContains(string $expected, string $message = "") {
        this.assertThat($expected, new ContentsNotContain(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stdout` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string $message Failure message
     */
    void assertOutputRegExp(string $pattern, string $message = "") {
        this.assertThat($pattern, new ContentsRegExp(_out.messages(), "output"), $message);
    }

    /**
     * Check that a row of cells exists in the output.
     *
     * @param array $row Row of cells to ensure exist in the output.
     * @param string $message Failure message.
     */
    protected void assertOutputContainsRow(array $row, string $message = "") {
        this.assertThat($row, new ContentsContainRow(_out.messages(), "output"), $message);
    }

    /**
     * Asserts `stderr` contains expected output
     *
     * @param string $expected Expected output
     * @param string $message Failure message
     */
    void assertErrorContains(string $expected, string $message = "") {
        this.assertThat($expected, new ContentsContain(_err.messages(), "error output"), $message);
    }

    /**
     * Asserts `stderr` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string $message Failure message
     */
    void assertErrorRegExp(string $pattern, string $message = "") {
        this.assertThat($pattern, new ContentsRegExp(_err.messages(), "error output"), $message);
    }

    /**
     * Asserts that `stderr` is empty
     *
     * @param string $message The message to output when the assertion fails.
     */
    void assertErrorEmpty(string $message = "") {
        this.assertThat(null, new ContentsEmpty(_err.messages(), "error output"), $message);
    }

    /**
     * Builds the appropriate command dispatcher
     *
     * @return uim.cake.consoles.CommandRunner|uim.cake.consoles.TestSuite\LegacyCommandRunner
     */
    protected function makeRunner() {
        if (_useCommandRunner) {
            /** @var uim.cake.Core\IConsoleApplication $app */
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
    protected string[] commandStringToArgs(string $command) {
        $charCount = strlen($command);
        $argv = null;
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

            $arg ~= $char;
        }
        $argv[] = $arg;

        return $argv;
    }
}
