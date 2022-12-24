

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console\TestSuite;

import uim.cake.Console\ConsoleIo;
import uim.cake.Console\Shell;
import uim.cake.Console\ShellDispatcher;

/**
 * Allows injecting mock IO into shells
 */
class LegacyShellDispatcher : ShellDispatcher
{
    /**
     * @var \Cake\Console\ConsoleIo
     */
    protected $_io;

    /**
     * Constructor
     *
     * @param array $args Argument array
     * @param bool $bootstrap Initialize environment
     * @param \Cake\Console\ConsoleIo|null $io ConsoleIo
     */
    public this(array $args = [], bool $bootstrap = true, ?ConsoleIo $io = null)
    {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        _io = $io;
        parent::__construct($args, $bootstrap);
    }

    /**
     * Injects mock and stub io components into the shell
     *
     * @param string $className Class name
     * @param string $shortName Short name
     * @return \Cake\Console\Shell
     */
    protected function _createShell(string $className, string $shortName): Shell
    {
        [$plugin] = pluginSplit($shortName);
        /** @var \Cake\Console\Shell $instance */
        $instance = new $className(_io);
        if ($plugin) {
            $instance.plugin = trim($plugin, ".");
        }

        return $instance;
    }
}
