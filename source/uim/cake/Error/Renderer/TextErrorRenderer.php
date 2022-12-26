


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
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
    /**
     * @inheritDoc
     */
    function write(string $out): void
    {
        echo $out;
    }

    /**
     * @inheritDoc
     */
    function render(PhpError $error, bool $debug): string
    {
        if (!$debug) {
            return '';
        }

        return sprintf(
            "%s: %s :: %s on line %s of %s\nTrace:\n%s",
            $error.getLabel(),
            $error.getCode(),
            $error.getMessage(),
            $error.getLine() ?? '',
            $error.getFile() ?? '',
            $error.getTraceAsString(),
        );
    }
}
