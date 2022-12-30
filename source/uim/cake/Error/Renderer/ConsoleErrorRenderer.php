


 *


 * @since         4.4.0
  */module uim.cake.errors.Renderer;

import uim.cake.consoles.ConsoleOutput;
import uim.cake.errors.ErrorRendererInterface;
import uim.cake.errors.PhpError;

/**
 * Plain text error rendering with a stack trace.
 *
 * Writes to STDERR via a Cake\Console\ConsoleOutput instance for console environments
 */
class ConsoleErrorRenderer : ErrorRendererInterface
{
    /**
     * @var uim.cake.consoles.ConsoleOutput
     */
    protected $output;

    /**
     */
    protected bool $trace = false;

    /**
     * Constructor.
     *
     * ### Options
     *
     * - `stderr` - The ConsoleOutput instance to use. Defaults to `php://stderr`
     * - `trace` - Whether or not stacktraces should be output.
     *
     * @param array $config Error handling configuration.
     */
    this(array $config) {
        this.output = $config["stderr"] ?? new ConsoleOutput("php://stderr");
        this.trace = (bool)($config["trace"] ?? false);
    }


    function write(string $out): void
    {
        this.output.write($out);
    }


    function render(PhpError $error, bool $debug): string
    {
        $trace = "";
        if (this.trace) {
            $trace = "\n<info>Stack Trace:</info>\n\n" . $error.getTraceAsString();
        }

        return sprintf(
            "<error>%s: %s :: %s</error> on line %s of %s%s",
            $error.getLabel(),
            $error.getCode(),
            $error.getMessage(),
            $error.getLine() ?? "",
            $error.getFile() ?? "",
            $trace
        );
    }
}
