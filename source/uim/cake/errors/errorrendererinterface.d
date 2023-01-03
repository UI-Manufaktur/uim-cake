


 *


 * @since         4.4.0
  */module uim.cake.Error;

/**
 * Interface for PHP error rendering implementations
 *
 * The core provided implementations of this interface are used
 * by Debugger and ErrorTrap to render PHP errors.
 */
interface ErrorRendererInterface
{
    /**
     * Render output for the provided error.
     *
     * @param uim.cake.errors.PhpError $error The error to be rendered.
     * @param bool $debug Whether or not the application is in debug mode.
     * @return string The output to be echoed.
     */
    string render(PhpError $error, bool $debug);

    /**
     * Write output to the renderer"s output stream
     *
     * @param string $out The content to output.
     */
    void write(string $out);
}
