module uim.cake.consoles.TestSuite;

import uim.cake.consoles.ConsoleOutput;

/**
 * StubOutput makes testing shell commands/shell helpers easier.
 *
 * You can use this class by injecting it into a ConsoleIo instance
 * that your command/task/helper uses:
 *
 * ```
 * import uim.cake.consoles.ConsoleIo;
 * import uim.cake.consoles.TestSuite\StubConsoleOutput;
 *
 * $output = new StubConsoleOutput();
 * $io = new ConsoleIo($output);
 * ```
 */
class StubConsoleOutput : ConsoleOutput
{
    /**
     * Buffered messages.
     *
     * @var array<string>
     */
    protected _out = null;

    /**
     * Write output to the buffer.
     *
     * @param array<string>|string $message A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     */
    int write($message, int $newlines = 1) {
        foreach ((array)$message as $line) {
            _out[] = $line;
        }

        $newlines--;
        while ($newlines > 0) {
            _out[] = "";
            $newlines--;
        }

        return 0;
    }

    /**
     * Get the buffered output.
     */
    string[] messages() {
        return _out;
    }

    /**
     * Get the output as a string
     */
    string output() {
        return implode("\n", _out);
    }
}
