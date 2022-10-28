module uim.cake.TestSuite\Stub;

import uim.cake.console.consoleOutput as ConsoleOutputBase;

/**
 * StubOutput makes testing shell commands/shell helpers easier.
 *
 * You can use this class by injecting it into a ConsoleIo instance
 * that your command/task/helper uses:
 *
 * ```
 * import uim.cake.console.consoleIo;
 * import uim.cake.TestSuite\Stub\ConsoleOutput;
 *
 * $output = new ConsoleOutput();
 * $io = new ConsoleIo($output);
 * ```
 */
class ConsoleOutput : ConsoleOutputBase
{
    /**
     * Buffered messages.
     *
     * @var array<string>
     */
    protected $_out = [];

    /**
     * Write output to the buffer.
     *
     * @param array<string>|string myMessage A string or an array of strings to output
     * @param int $newlines Number of newlines to append
     * @return int
     */
    function write(myMessage, int $newlines = 1): int
    {
        foreach ((array)myMessage as $line) {
            this._out[] = $line;
        }

        $newlines--;
        while ($newlines > 0) {
            this._out[] = '';
            $newlines--;
        }

        return 0;
    }

    /**
     * Get the buffered output.
     *
     * @return array<string>
     */
    function messages(): array
    {
        return this._out;
    }

    /**
     * Get the output as a string
     *
     * @return string
     */
    function output(): string
    {
        return implode("\n", this._out);
    }
}
