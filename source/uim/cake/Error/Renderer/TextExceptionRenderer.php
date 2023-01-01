


 *


 * @since         4.4.0
  */module uim.cake.errors.Renderer;

use Throwable;

/**
 * Plain text exception rendering with a stack trace.
 *
 * Useful in CI or plain text environments.
 *
 * @todo 5.0 Implement uim.cake.errors.ExceptionRendererInterface. This implementation can"t implement
 *  the concrete interface because the return types are not compatible.
 */
class TextExceptionRenderer
{
    /**
     * @var \Throwable
     */
    private $error;

    /**
     * Constructor.
     *
     * @param \Throwable $error The error to render.
     */
    this(Throwable $error) {
        this.error = $error;
    }

    /**
     * Render an exception into a plain text message.
     *
     * @return \Psr\Http\messages.IResponse|string
     */
    function render() {
        return sprintf(
            "%s : %s on line %s of %s\nTrace:\n%s",
            this.error.getCode(),
            this.error.getMessage(),
            this.error.getLine(),
            this.error.getFile(),
            this.error.getTraceAsString(),
        );
    }

    /**
     * Write output to stdout.
     *
     * @param string $output The output to print.
     */
    void write($output): void
    {
        echo $output;
    }
}
