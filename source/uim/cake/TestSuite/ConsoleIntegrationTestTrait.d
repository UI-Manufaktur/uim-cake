

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.7.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.TestSuite;

import uim.baklava.command\Command;
import uim.baklava.console.commandRunner;
import uim.baklava.console.consoleIo;
import uim.baklava.console.Exception\StopException;
import uim.baklava.TestSuite\Constraint\Console\ContentsContain;
import uim.baklava.TestSuite\Constraint\Console\ContentsContainRow;
import uim.baklava.TestSuite\Constraint\Console\ContentsEmpty;
import uim.baklava.TestSuite\Constraint\Console\ContentsNotContain;
import uim.baklava.TestSuite\Constraint\Console\ContentsRegExp;
import uim.baklava.TestSuite\Constraint\Console\ExitCode;
import uim.baklava.TestSuite\Stub\ConsoleInput;
import uim.baklava.TestSuite\Stub\ConsoleOutput;
import uim.baklava.TestSuite\Stub\MissingConsoleInputException;
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
     * @var \Cake\TestSuite\Stub\ConsoleOutput
     */
    protected $_out;

    /**
     * Console error output stub
     *
     * @var \Cake\TestSuite\Stub\ConsoleOutput
     */
    protected $_err;

    /**
     * Console input mock
     *
     * @var \Cake\Console\ConsoleInput
     */
    protected $_in;

    /**
     * Runs CLI integration test
     *
     * @param string $command Command to run
     * @param array $input Input values to pass to an interactive shell
     * @throws \Cake\TestSuite\Stub\MissingConsoleInputException
     * @throws \RuntimeException
     * @return void
     */
    function exec(string $command, array $input = []): void
    {
        $runner = this.makeRunner();

        if (this._out === null) {
            this._out = new ConsoleOutput();
        }
        if (this._err === null) {
            this._err = new ConsoleOutput();
        }
        if (this._in === null) {
            this._in = new ConsoleInput($input);
        } elseif ($input) {
            throw new RuntimeException('You can use `$input` only if `$_in` property is null and will be reset.');
        }

        $args = this.commandStringToArgs("cake $command");
        $io = new ConsoleIo(this._out, this._err, this._in);

        try {
            this._exitCode = $runner.run($args, $io);
        } catch (MissingConsoleInputException $e) {
            myMessages = this._out.messages();
            if (count(myMessages)) {
                $e.setQuestion(myMessages[count(myMessages) - 1]);
            }
            throw $e;
        } catch (StopException myException) {
            this._exitCode = myException.getCode();
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
        this._exitCode = null;
        this._out = null;
        this._err = null;
        this._in = null;
        this._useCommandRunner = false;
    }

    /**
     * Set this test case to use the CommandRunner rather than the legacy
     * ShellDispatcher
     *
     * @return void
     */
    function useCommandRunner(): void
    {
        this._useCommandRunner = true;
    }

    /**
     * Asserts shell exited with the expected code
     *
     * @param int $expected Expected exit code
     * @param string myMessage Failure message
     * @return void
     */
    function assertExitCode(int $expected, string myMessage = ''): void
    {
        this.assertThat($expected, new ExitCode(this._exitCode), myMessage);
    }

    /**
     * Asserts shell exited with the Command::CODE_SUCCESS
     *
     * @param string myMessage Failure message
     * @return void
     */
    function assertExitSuccess(myMessage = '') {
        this.assertThat(Command::CODE_SUCCESS, new ExitCode(this._exitCode), myMessage);
    }

    /**
     * Asserts shell exited with Command::CODE_ERROR
     *
     * @param string myMessage Failure message
     * @return void
     */
    function assertExitError(myMessage = '') {
        this.assertThat(Command::CODE_ERROR, new ExitCode(this._exitCode), myMessage);
    }

    /**
     * Asserts that `stdout` is empty
     *
     * @param string myMessage The message to output when the assertion fails.
     * @return void
     */
    function assertOutputEmpty(string myMessage = ''): void
    {
        this.assertThat(null, new ContentsEmpty(this._out.messages(), 'output'), myMessage);
    }

    /**
     * Asserts `stdout` contains expected output
     *
     * @param string $expected Expected output
     * @param string myMessage Failure message
     * @return void
     */
    function assertOutputContains(string $expected, string myMessage = ''): void
    {
        this.assertThat($expected, new ContentsContain(this._out.messages(), 'output'), myMessage);
    }

    /**
     * Asserts `stdout` does not contain expected output
     *
     * @param string $expected Expected output
     * @param string myMessage Failure message
     * @return void
     */
    function assertOutputNotContains(string $expected, string myMessage = ''): void
    {
        this.assertThat($expected, new ContentsNotContain(this._out.messages(), 'output'), myMessage);
    }

    /**
     * Asserts `stdout` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string myMessage Failure message
     * @return void
     */
    function assertOutputRegExp(string $pattern, string myMessage = ''): void
    {
        this.assertThat($pattern, new ContentsRegExp(this._out.messages(), 'output'), myMessage);
    }

    /**
     * Check that a row of cells exists in the output.
     *
     * @param array $row Row of cells to ensure exist in the output.
     * @param string myMessage Failure message.
     * @return void
     */
    protected auto assertOutputContainsRow(array $row, string myMessage = ''): void
    {
        this.assertThat($row, new ContentsContainRow(this._out.messages(), 'output'), myMessage);
    }

    /**
     * Asserts `stderr` contains expected output
     *
     * @param string $expected Expected output
     * @param string myMessage Failure message
     * @return void
     */
    function assertErrorContains(string $expected, string myMessage = ''): void
    {
        this.assertThat($expected, new ContentsContain(this._err.messages(), 'error output'), myMessage);
    }

    /**
     * Asserts `stderr` contains expected regexp
     *
     * @param string $pattern Expected pattern
     * @param string myMessage Failure message
     * @return void
     */
    function assertErrorRegExp(string $pattern, string myMessage = ''): void
    {
        this.assertThat($pattern, new ContentsRegExp(this._err.messages(), 'error output'), myMessage);
    }

    /**
     * Asserts that `stderr` is empty
     *
     * @param string myMessage The message to output when the assertion fails.
     * @return void
     */
    function assertErrorEmpty(string myMessage = ''): void
    {
        this.assertThat(null, new ContentsEmpty(this._err.messages(), 'error output'), myMessage);
    }

    /**
     * Builds the appropriate command dispatcher
     *
     * @return \Cake\Console\CommandRunner|\Cake\TestSuite\LegacyCommandRunner
     */
    protected auto makeRunner() {
        if (this._useCommandRunner) {
            /** @var \Cake\Core\ConsoleApplicationInterface $app */
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
    protected auto commandStringToArgs(string $command): array
    {
        $charCount = strlen($command);
        $argv = [];
        $arg = '';
        $inDQuote = false;
        $inSQuote = false;
        for ($i = 0; $i < $charCount; $i++) {
            $char = substr($command, $i, 1);

            // end of argument
            if ($char === ' ' && !$inDQuote && !$inSQuote) {
                if ($arg !== '') {
                    $argv[] = $arg;
                }
                $arg = '';
                continue;
            }

            // exiting single quote
            if ($inSQuote && $char === "'") {
                $inSQuote = false;
                continue;
            }

            // exiting double quote
            if ($inDQuote && $char === '"') {
                $inDQuote = false;
                continue;
            }

            // entering double quote
            if ($char === '"' && !$inSQuote) {
                $inDQuote = true;
                continue;
            }

            // entering single quote
            if ($char === "'" && !$inDQuote) {
                $inSQuote = true;
                continue;
            }

            $arg .= $char;
        }
        $argv[] = $arg;

        return $argv;
    }
}
