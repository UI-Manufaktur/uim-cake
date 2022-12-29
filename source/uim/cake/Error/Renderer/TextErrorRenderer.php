


 *


 * @since         4.4.0
  */
module uim.cake.errors.Renderer;

import uim.cake.errors.ErrorRendererInterface;
import uim.cake.errors.PhpError;

/**
 * Plain text error rendering with a stack trace.
 *
 * Useful in CLI environments.
 */
class TextErrorRenderer : ErrorRendererInterface
{

    function write(string $out): void
    {
        echo $out;
    }


    function render(PhpError $error, bool $debug): string
    {
        if (!$debug) {
            return "";
        }

        return sprintf(
            "%s: %s :: %s on line %s of %s\nTrace:\n%s",
            $error.getLabel(),
            $error.getCode(),
            $error.getMessage(),
            $error.getLine() ?? "",
            $error.getFile() ?? "",
            $error.getTraceAsString(),
        );
    }
}
