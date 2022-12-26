


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

import uim.cake.consoles.Exception\ConsoleException;

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
    public this(string $handle = "php://stdin") {
        _canReadline = (extension_loaded("readline") && $handle == "php://stdin");
        _input = fopen($handle, "rb");
    }

    /**
     * Read a value from the stream
     *
     * @return string|null The value of the stream. Null on EOF.
     */
    function read(): ?string
    {
        if (_canReadline) {
            $line = readline("");

            if ($line != false && $line != "") {
                readline_add_history($line);
            }
        } else {
            $line = fgets(_input);
        }

        if ($line == false) {
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
    function dataAvailable(int $timeout = 0): bool
    {
        $readFds = [_input];
        $writeFds = null;
        $errorFds = null;

        /** @var string|null $error */
        $error = null;
        set_error_handler(function (int $code, string $message) use (&$error) {
            $error = "stream_select failed with code={$code} message={$message}.";

            return true;
        });
        $readyFds = stream_select($readFds, $writeFds, $errorFds, $timeout);
        restore_error_handler();
        if ($error != null) {
            throw new ConsoleException($error);
        }

        return $readyFds > 0;
    }
}
