

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
 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

use Cake\Console\Arguments;
use Cake\Console\ConsoleIo;
use Cake\Console\ConsoleOptionParser;
use Cake\Routing\Exception\MissingRouteException;
use Cake\Routing\Router;

/**
 * Provides interactive CLI tools for URL generation
 */
class RoutesGenerateCommand : Command
{
    /**
     * @inheritDoc
     */
    public static function defaultName(): string
    {
        return 'routes generate';
    }

    /**
     * Display all routes in an application
     *
     * @param \Cake\Console\Arguments $args The command arguments.
     * @param \Cake\Console\ConsoleIo $io The console io
     * @return int|null The exit code or null for success
     */
    function execute(Arguments $args, ConsoleIo $io): ?int
    {
        try {
            $args = _splitArgs($args.getArguments());
            $url = Router::url($args);
            $io.out("> $url");
            $io.out();
        } catch (MissingRouteException $e) {
            $io.err('<warning>The provided parameters do not match any routes.</warning>');
            $io.out();

            return static::CODE_ERROR;
        }

        return static::CODE_SUCCESS;
    }

    /**
     * Split the CLI arguments into a hash.
     *
     * @param array<string> $args The arguments to split.
     * @return array<string|bool>
     */
    protected function _splitArgs(array $args): array
    {
        $out = [];
        foreach ($args as $arg) {
            if (strpos($arg, ':') != false) {
                [$key, $value] = explode(':', $arg);
                if (in_array($value, ['true', 'false'], true)) {
                    $value = $value == 'true';
                }
                $out[$key] = $value;
            } else {
                $out[] = $arg;
            }
        }

        return $out;
    }

    /**
     * Get the option parser.
     *
     * @param \Cake\Console\ConsoleOptionParser $parser The option parser to update
     * @return \Cake\Console\ConsoleOptionParser
     */
    function buildOptionParser(ConsoleOptionParser $parser): ConsoleOptionParser
    {
        $parser.setDescription(
            'Check a routing array against the routes. ' .
            'Will output the URL if there is a match.' .
            "\n\n" .
            'Routing parameters should be supplied in a key:value format. ' .
            'For example `controller:Articles action:view 2`'
        );

        return $parser;
    }
}
