module uim.baklava.errors;

import uim.baklava.command\Command;
import uim.baklava.console.consoleOutput;
import uim.baklava.console.Exception\ConsoleException;
use Throwable;

/**
 * Error Handler for Cake console. Does simple printing of the
 * exception that occurred and the stack trace of the error.
 */
class ConsoleErrorHandler : BaseErrorHandler
{
    /**
     * Standard error stream.
     *
     * @var \Cake\Console\ConsoleOutput
     */
    protected $_stderr;

    /**
     * Constructor
     *
     * @param array<string, mixed> myConfig Config options for the error handler.
     */
    this(array myConfig = []) {
        myConfig += [
            'stderr' => new ConsoleOutput('php://stderr'),
            'log' => false,
        ];

        this.setConfig(myConfig);
        this._stderr = this._config['stderr'];
    }

    /**
     * Handle errors in the console environment. Writes errors to stderr,
     * and logs messages if Configure::read('debug') is false.
     *
     * @param \Throwable myException Exception instance.
     * @return void
     * @throws \Exception When renderer class not found
     * @see https://secure.php.net/manual/en/function.set-exception-handler.php
     */
    function handleException(Throwable myException): void
    {
        this._displayException(myException);
        this.logException(myException);

        $exitCode = Command::CODE_ERROR;
        if (myException instanceof ConsoleException) {
            $exitCode = myException.getCode();
        }
        this._stop($exitCode);
    }

    /**
     * Prints an exception to stderr.
     *
     * @param \Throwable myException The exception to handle
     * @return void
     */
    protected auto _displayException(Throwable myException): void
    {
        myErrorName = 'Exception:';
        if (myException instanceof FatalErrorException) {
            myErrorName = 'Fatal Error:';
        }

        myMessage = sprintf(
            "<error>%s</error> %s\nIn [%s, line %s]\n",
            myErrorName,
            myException.getMessage(),
            myException.getFile(),
            myException.getLine()
        );
        this._stderr.write(myMessage);
    }

    /**
     * Prints an error to stderr.
     *
     * Template method of BaseErrorHandler.
     *
     * @param array myError An array of error data.
     * @param bool $debug Whether the app is in debug mode.
     * @return void
     */
    protected auto _displayError(array myError, bool $debug): void
    {
        myMessage = sprintf(
            "%s\nIn [%s, line %s]",
            myError['description'],
            myError['file'],
            myError['line']
        );
        myMessage = sprintf(
            "<error>%s Error:</error> %s\n",
            myError['error'],
            myMessage
        );
        this._stderr.write(myMessage);
    }

    /**
     * Stop the execution and set the exit code for the process.
     *
     * @param int $code The exit code.
     * @return void
     */
    protected auto _stop(int $code): void
    {
        exit($code);
    }
}