module uim.cake.TestSuite\Stub;

import uim.cake.console.consoleInput as ConsoleInputBase;
use NumberFormatter;

/**
 * Stub class used by the console integration harness.
 *
 * This class enables input to be stubbed and have exceptions
 * raised when no answer is available.
 */
class ConsoleInput : ConsoleInputBase
{
    /**
     * Reply values for ask() and askChoice()
     *
     * @var array<string>
     */
    protected $replies = [];

    /**
     * Current message index
     *
     * @var int
     */
    protected $currentIndex = -1;

    /**
     * Constructor
     *
     * @param array<string> $replies A list of replies for read()
     */
    this(array $replies) {
        super.this();

        this.replies = $replies;
    }

    /**
     * Read a reply
     *
     * @return string The value of the reply
     */
    function read(): string
    {
        this.currentIndex += 1;

        if (!isset(this.replies[this.currentIndex])) {
            $total = count(this.replies);
            $formatter = new NumberFormatter('en', NumberFormatter::ORDINAL);
            $nth = $formatter.format(this.currentIndex + 1);

            $replies = implode(', ', this.replies);
            myMessage = "There are no more input replies available. This is the {$nth} read operation, " .
                "only {$total} replies were set.\nThe provided replies are: {$replies}";
            throw new MissingConsoleInputException(myMessage);
        }

        return this.replies[this.currentIndex];
    }

    /**
     * Check if data is available on stdin
     *
     * @param int $timeout An optional time to wait for data
     * @return bool True for data available, false otherwise
     */
    function dataAvailable($timeout = 0): bool
    {
        return true;
    }
}
