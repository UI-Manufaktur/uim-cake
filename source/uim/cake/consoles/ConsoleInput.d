module uim.cake.console;

import uim.cake.console.Exception\ConsoleException;

/**
 * Object wrapper for interacting with stdin
 */
class ConsoleInput
{
    /**
     * Input value.
     *
     * @var resource
     */
    protected $_input;

    /**
     * Can this instance use readline?
     * Two conditions must be met:
     * 1. Readline support must be enabled.
     * 2. Handle we are attached to must be stdin.
     * Allows rich editing with arrow keys and history when inputting a string.
     *
     * @var bool
     */
    protected $_canReadline;

    /**
     * Constructor
     *
     * @param string $handle The location of the stream to use as input.
     */
    this(string $handle = "php://stdin") {
        this._canReadline = (extension_loaded("readline") && $handle === "php://stdin");
        this._input = fopen($handle, "rb");
    }

    /**
     * Read a value from the stream
     *
     * @return string|null The value of the stream. Null on EOF.
     */
    string read() {
        if (this._canReadline) {
            $line = readline("");

            if ($line !== false && $line !== "") {
                readline_add_history($line);
            }
        } else {
            $line = fgets(this._input);
        }

        if ($line === false) {
            return null;
        }

        return $line;
    }

    /**
     * Check if data is available on stdin
     *
     * @param int $timeout An optional time to wait for data
     * @return bool True for data available, false otherwise
     */
    bool dataAvailable(int $timeout = 0) {
        $readFds = [this._input];
        $writeFds = null;
        myErrorFds = null;

        /** @var string|null myError */
        myError = null;
        set_error_handler(function (int $code, string myMessage) use (&myError) {
            myError = "stream_select failed with code={$code} message={myMessage}.";

            return true;
        });
        $readyFds = stream_select($readFds, $writeFds, myErrorFds, $timeout);
        restore_error_handler();
        if (myError !== null) {
            throw new ConsoleException(myError);
        }

        return $readyFds > 0;
    }
}
