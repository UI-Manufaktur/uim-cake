

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *



 */
module uim.cake.consoles.TestSuite;

import uim.cake.consoles.ConsoleIo;
import uim.cake.consoles.Shell;
import uim.cake.consoles.ShellDispatcher;

/**
 * Allows injecting mock IO into shells
 */
class LegacyShellDispatcher : ShellDispatcher
{
    /**
     * @var uim.cake.consoles.ConsoleIo
     */
    protected $_io;

    /**
     * Constructor
     *
     * @param array $args Argument array
     * @param bool $bootstrap Initialize environment
     * @param uim.cake.consoles.ConsoleIo|null $io ConsoleIo
     */
    this(array $args = [], bool $bootstrap = true, ?ConsoleIo $io = null) {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        _io = $io;
        super(($args, $bootstrap);
    }

    /**
     * Injects mock and stub io components into the shell
     *
     * @param string $className Class name
     * @param string $shortName Short name
     * @return uim.cake.consoles.Shell
     */
    protected function _createShell(string $className, string $shortName): Shell
    {
        [$plugin] = pluginSplit($shortName);
        /** @var uim.cake.consoles.Shell $instance */
        $instance = new $className(_io);
        if ($plugin) {
            $instance.plugin = trim($plugin, ".");
        }

        return $instance;
    }
}
