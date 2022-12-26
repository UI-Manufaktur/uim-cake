

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Error\Renderer;

import uim.cake.consoles.ConsoleOutput;
import uim.cake.Error\ErrorRendererInterface;
import uim.cake.Error\PhpError;

/**
 * Plain text error rendering with a stack trace.
 *
 * Writes to STDERR via a Cake\Console\ConsoleOutput instance for console environments
 */
class ConsoleErrorRenderer : ErrorRendererInterface
{
    /**
     * @var \Cake\Console\ConsoleOutput
     */
    protected $output;

    /**
     * @var bool
     */
    protected $trace = false;

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
    public this(array $config)
    {
        this.output = $config['stderr'] ?? new ConsoleOutput('php://stderr');
        this.trace = (bool)($config['trace'] ?? false);
    }

    /**
     * @inheritDoc
     */
    function write(string $out): void
    {
        this.output.write($out);
    }

    /**
     * @inheritDoc
     */
    function render(PhpError $error, bool $debug): string
    {
        $trace = '';
        if (this.trace) {
            $trace = "\n<info>Stack Trace:</info>\n\n" . $error.getTraceAsString();
        }

        return sprintf(
            '<error>%s: %s :: %s</error> on line %s of %s%s',
            $error.getLabel(),
            $error.getCode(),
            $error.getMessage(),
            $error.getLine() ?? '',
            $error.getFile() ?? '',
            $trace
        );
    }
}
