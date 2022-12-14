/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.consoles;

@safe:
import uim.cake;

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
    protected _input;

    /**
     * Can this instance use readline?
     * Two conditions must be met:
     * 1. Readline support must be enabled.
     * 2. Handle we are attached to must be stdin.
     * Allows rich editing with arrow keys and history when inputting a string.
     */
    protected bool _canReadline;

    /**
     * Constructor
     *
     * @param string $handle The location of the stream to use as input.
     */
    this(string $handle = "php://stdin") {
        _canReadline = (extension_loaded("readline") && $handle == "php://stdin");
        _input = fopen($handle, "rb");
    }

    /**
     * Read a value from the stream
     *
     * @return string|null The value of the stream. Null on EOF.
     */
    Nullable!string read() {
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
    bool dataAvailable(int $timeout = 0) {
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
