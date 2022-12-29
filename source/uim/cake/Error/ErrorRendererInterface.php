


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Error;

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
     * @param \Cake\Error\PhpError $error The error to be rendered.
     * @param bool $debug Whether or not the application is in debug mode.
     * @return string The output to be echoed.
     */
    function render(PhpError $error, bool $debug): string;

    /**
     * Write output to the renderer"s output stream
     *
     * @param string $out The content to output.
     * @return void
     */
    function write(string $out): void;
}
