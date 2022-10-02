

/**
 * CakePHP(tm) : Rapid Development Framework (http://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (http://cakefoundation.org)
 * @since         3.5.0
 * @license       http://www.opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.TestSuite;

import uim.cake.console.consoleIo;
import uim.cake.console.Shell;
import uim.cake.console.ShellDispatcher;

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
    this(array $args = [], bool $bootstrap = true, ?ConsoleIo $io = null)
    {
        /** @psalm-suppress PossiblyNullPropertyAssignmentValue */
        this._io = $io;
        super.this($args, $bootstrap);
    }

    /**
     * Injects mock and stub io components into the shell
     *
     * @param string myClassName Class name
     * @param string $shortName Short name
     * @return \Cake\Console\Shell
     */
    protected auto _createShell(string myClassName, string $shortName): Shell
    {
        [myPlugin] = pluginSplit($shortName);
        /** @var \Cake\Console\Shell $instance */
        $instance = new myClassName(this._io);
        if (myPlugin) {
            $instance.plugin = trim(myPlugin, '.');
        }

        return $instance;
    }
}
