


 *


 * @since         2.5.0
  */module uim.cake.Shell\Task;

import uim.cake.consoles.Shell;
import uim.cake.core.App;
import uim.cake.core.Plugin;
import uim.cake.filesystems.Filesystem;
import uim.cake.utilities.Inflector;

/**
 * Base class for Shell Command reflection.
 *
 * @internal
 */
class CommandTask : Shell
{
    /**
     * Gets the shell command listing.
     */
    array getShellList() {
        $skipFiles = ["app"];
        $hiddenCommands = ["command_list", "completion"];
        $plugins = Plugin::loaded();
        $shellList = array_fill_keys($plugins, null) + ["CORE": null, "app": null];

        $appPath = App::classPath("Shell");
        $shellList = _findShells($shellList, $appPath[0], "app", $skipFiles);

        $appPath = App::classPath("Command");
        $shellList = _findShells($shellList, $appPath[0], "app", $skipFiles);

        $skipCore = array_merge($skipFiles, $hiddenCommands, $shellList["app"]);
        $corePath = dirname(__DIR__);
        $shellList = _findShells($shellList, $corePath, "CORE", $skipCore);

        $corePath = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR ~ "Command";
        $shellList = _findShells($shellList, $corePath, "CORE", $skipCore);

        foreach ($plugins as $plugin) {
            $pluginPath = Plugin::classPath($plugin) ~ "Shell";
            $shellList = _findShells($shellList, $pluginPath, $plugin, []);
        }

        return array_filter($shellList);
    }

    /**
     * Find shells in $path and add them to $shellList
     *
     * @param array<string, mixed> $shellList The shell listing array.
     * @param string $path The path to look in.
     * @param string aKey The key to add shells to
     * @param array<string> $skip A list of commands to exclude.
     * @return array<string, mixed> The updated list of shells.
     */
    protected array _findShells(array $shellList, string $path, string aKey, array $skip) {
        $shells = _scanDir($path);

        return _appendShells($key, $shells, $shellList, $skip);
    }

    /**
     * Scan the provided paths for shells, and append them into $shellList
     *
     * @param string $type The type of object.
     * @param array<string> $shells The shell names.
     * @param array<string, mixed> $shellList List of shells.
     * @param array<string> $skip List of command names to skip.
     * @return array<string, mixed> The updated $shellList
     */
    protected array _appendShells(string $type, array $shells, array $shellList, array $skip) {
        $shellList[$type] = $shellList[$type] ?? [];

        foreach ($shells as $shell) {
            $name = Inflector::underscore(preg_replace("/(Shell|Command)$/", "", $shell));
            if (!hasAllValues($name, $skip, true)) {
                $shellList[$type][] = $name;
            }
        }
        sort($shellList[$type]);

        return $shellList;
    }

    /**
     * Scan a directory for .php files and return the class names that
     * should be within them.
     *
     * @param string $dir The directory to read.
     * @return array<string> The list of shell classnames based on conventions.
     */
    protected array _scanDir(string $dir) {
        if (!is_dir($dir)) {
            return [];
        }

        $fs = new Filesystem();
        $files = $fs.find($dir, "/\.php$/");

        $shells = null;
        foreach ($files as $file) {
            $shells[] = $file.getBasename(".php");
        }

        sort($shells);

        return $shells;
    }
}
