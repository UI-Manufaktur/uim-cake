


 *


 * @since         4.4.0
  */module uim.cake.errors.Renderer;

import uim.cake.consoles.ConsoleOutput;
import uim.cake.core.Configure;
import uim.cake.core.exceptions.CakeException;
use Psr\Http\messages.IServerRequest;
use Throwable;

/**
 * Plain text exception rendering with a stack trace.
 *
 * Useful in CI or plain text environments.
 *
 * @todo 5.0 Implement uim.cake.errors.ExceptionRendererInterface. This implementation can"t implement
 *  the concrete interface because the return types are not compatible.
 */
class ConsoleExceptionRenderer
{
    /**
     * @var \Throwable
     */
    private $error;

    /**
     * @var uim.cake.consoles.ConsoleOutput
     */
    private $output;

    /**
     * @var bool
     */
    private $trace;

    /**
     * Constructor.
     *
     * @param \Throwable $error The error to render.
     * @param \Psr\Http\messages.IServerRequest|null $request Not used.
     * @param array $config Error handling configuration.
     */
    this(Throwable $error, ?IServerRequest $request, array $config) {
        this.error = $error;
        this.output = $config["stderr"] ?? new ConsoleOutput("php://stderr");
        this.trace = $config["trace"] ?? true;
    }

    /**
     * Render an exception into a plain text message.
     *
     * @return \Psr\Http\messages.IResponse|string
     */
    function render() {
        $exceptions = [this.error];
        $previous = this.error.getPrevious();
        while ($previous != null) {
            $exceptions[] = $previous;
            $previous = $previous.getPrevious();
        }
        $out = [];
        foreach ($exceptions as $i: $error) {
            $out = array_merge($out, this.renderException($error, $i));
        }

        return join("\n", $out);
    }

    /**
     * Render an individual exception
     *
     * @param \Throwable $exception The exception to render.
     * @param int $index Exception index in the chain
     * @return array
     */
    protected function renderException(Throwable $exception, int $index): array
    {
        $out = [
            sprintf(
                "<error>%s[%s] %s</error> in %s on line %s",
                $index > 0 ? "Caused by " : "",
                get_class($exception),
                $exception.getMessage(),
                $exception.getFile(),
                $exception.getLine()
            ),
        ];

        $debug = Configure::read("debug");
        if ($debug && $exception instanceof CakeException) {
            $attributes = $exception.getAttributes();
            if ($attributes) {
                $out[] = "";
                $out[] = "<info>Exception Attributes</info>";
                $out[] = "";
                $out[] = var_export($exception.getAttributes(), true);
            }
        }

        if (this.trace) {
            $out[] = "";
            $out[] = "<info>Stack Trace:</info>";
            $out[] = "";
            $out[] = $exception.getTraceAsString();
            $out[] = "";
        }

        return $out;
    }

    /**
     * Write output to the output stream
     *
     * @param string $output The output to print.
     */
    void write($output): void
    {
        this.output.write($output);
    }
}
