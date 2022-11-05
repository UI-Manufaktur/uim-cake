

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         2.5.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.Shell\Task;

import uim.baklava.console.Shell;
import uim.baklava.core.App;
import uim.baklava.core.Plugin;
import uim.baklava.Filesystem\Filesystem;
import uim.baklava.utilities.Inflector;

/**
 * Base class for Shell Command reflection.
 *
 * @internal
 */
class CommandTask : Shell
{
    /**
     * Gets the shell command listing.
     *
     * @return array
     */
    auto getShellList() {
        $skipFiles = ['app'];
        myHiddenCommands = ['command_list', 'completion'];
        myPlugins = Plugin::loaded();
        $shellList = array_fill_keys(myPlugins, null) + ['CORE' => null, 'app' => null];

        $appPath = App::classPath('Shell');
        $shellList = this._findShells($shellList, $appPath[0], 'app', $skipFiles);

        $appPath = App::classPath('Command');
        $shellList = this._findShells($shellList, $appPath[0], 'app', $skipFiles);

        $skipCore = array_merge($skipFiles, myHiddenCommands, $shellList['app']);
        $corePath = dirname(__DIR__);
        $shellList = this._findShells($shellList, $corePath, 'CORE', $skipCore);

        $corePath = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR . 'Command';
        $shellList = this._findShells($shellList, $corePath, 'CORE', $skipCore);

        foreach (myPlugins as myPlugin) {
            myPluginPath = Plugin::classPath(myPlugin) . 'Shell';
            $shellList = this._findShells($shellList, myPluginPath, myPlugin, []);
        }

        return array_filter($shellList);
    }

    /**
     * Find shells in myPath and add them to $shellList
     *
     * @param array<string, mixed> $shellList The shell listing array.
     * @param string myPath The path to look in.
     * @param string myKey The key to add shells to
     * @param array<string> $skip A list of commands to exclude.
     * @return array<string, mixed> The updated list of shells.
     */
    protected auto _findShells(array $shellList, string myPath, string myKey, array $skip): array
    {
        $shells = this._scanDir(myPath);

        return this._appendShells(myKey, $shells, $shellList, $skip);
    }

    /**
     * Scan the provided paths for shells, and append them into $shellList
     *
     * @param string myType The type of object.
     * @param array<string> $shells The shell names.
     * @param array<string, mixed> $shellList List of shells.
     * @param array<string> $skip List of command names to skip.
     * @return array<string, mixed> The updated $shellList
     */
    protected auto _appendShells(string myType, array $shells, array $shellList, array $skip): array
    {
        $shellList[myType] = $shellList[myType] ?? [];

        foreach ($shells as $shell) {
            myName = Inflector::underscore(preg_replace('/(Shell|Command)$/', '', $shell));
            if (!in_array(myName, $skip, true)) {
                $shellList[myType][] = myName;
            }
        }
        sort($shellList[myType]);

        return $shellList;
    }

    /**
     * Scan a directory for .php files and return the class names that
     * should be within them.
     *
     * @param string $dir The directory to read.
     * @return array<string> The list of shell classnames based on conventions.
     */
    protected auto _scanDir(string $dir): array
    {
        if (!is_dir($dir)) {
            return [];
        }

        $fs = new Filesystem();
        myfiles = $fs.find($dir, '/\.php$/');

        $shells = [];
        foreach (myfiles as myfile) {
            $shells[] = myfile.getBasename('.php');
        }

        sort($shells);

        return $shells;
    }
}
