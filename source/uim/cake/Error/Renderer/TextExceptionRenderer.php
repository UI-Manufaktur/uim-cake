


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.errors.Renderer;

use Throwable;

/**
 * Plain text exception rendering with a stack trace.
 *
 * Useful in CI or plain text environments.
 *
 * @todo 5.0 Implement \Cake\Error\ExceptionRendererInterface. This implementation can't implement
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
    public this(Throwable $error) {
        this.error = $error;
    }

    /**
     * Render an exception into a plain text message.
     *
     * @return \Psr\Http\Message\IResponse|string
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
     * @return void
     */
    function write($output): void
    {
        echo $output;
    }
}
