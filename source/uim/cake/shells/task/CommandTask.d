
module uim.cake.shells.Task;

@safe:
import uim.cake;

// Base class for Shell Command reflection.
class CommandTask : Shell {
    /**
     * Gets the shell command listing.
     *
     * @return array
     */
    auto getShellList() {
        $skipFiles = ["app"];
        myHiddenCommands = ["command_list", "completion"];
        myPlugins = Plugin::loaded();
        myShellList = array_fill_keys(myPlugins, null) + ["CORE": null, "app": null];

        $appPath = App::classPath("Shell");
        myShellList = _findShells(myShellList, $appPath[0], "app", $skipFiles);

        $appPath = App::classPath("Command");
        myShellList = _findShells(myShellList, $appPath[0], "app", $skipFiles);

        $skipCore = array_merge($skipFiles, myHiddenCommands, myShellList["app"]);
        $corePath = dirname(__DIR__);
        myShellList = _findShells(myShellList, $corePath, "CORE", $skipCore);

        $corePath = dirname(dirname(__DIR__)) . DIRECTORY_SEPARATOR ~ "Command";
        myShellList = _findShells(myShellList, $corePath, "CORE", $skipCore);

        foreach (myPlugins as myPlugin) {
            myPluginPath = Plugin::classPath(myPlugin) ~ "Shell";
            myShellList = _findShells(myShellList, myPluginPath, myPlugin, []);
        }

        return array_filter(myShellList);
    }

    /**
     * Find shells in myPath and add them to myShellList
     *
     * @param array<string, mixed> myShellList The shell listing array.
     * @param string myPath The path to look in.
     * @param string myKey The key to add shells to
     * @param $skip A list of commands to exclude.
     * @return array<string, mixed> The updated list of shells.
     */
    protected auto _findShells(array myShellList, string myPath, string myKey, string[] $skip): array
    {
        myShells = _scanDir(myPath);

        return _appendShells(myKey, myShells, myShellList, $skip);
    }

    /**
     * Scan the provided paths for shells, and append them into myShellList
     *
     * @param string myType The type of object.
     * @param myShells The shell names.
     * @param array<string, mixed> myShellList List of shells.
     * @param $skip List of command names to skip.
     * @return array<string, mixed> The updated myShellList
     */
    protected auto _appendShells(string myType, string[] myShells, array myShellList, string[] $skip): array
    {
        myShellList[myType] = myShellList[myType] ?? [];

        foreach (myShells as myShell) {
            myName = Inflector::underscore(preg_replace("/(Shell|Command)$/", "", myShell));
            if (!in_array(myName, $skip, true)) {
                myShellList[myType][] = myName;
            }
        }
        sort(myShellList[myType]);

        return myShellList;
    }

    /**
     * Scan a directory for .php files and return the class names that
     * should be within them.
     *
     * @param string dir The directory to read.
     * @return The list of shell classnames based on conventions.
     */
    protected string[] _scanDir(string dir) {
        if (!is_dir($dir)) {
            return [];
        }

        $fs = new Filesystem();
        myfiles = $fs.find($dir, "/\.php$/");

        myShells = [];
        foreach (myfiles as myfile) {
            myShells[] = myfile.getBasename(".php");
        }

        sort(myShells);

        return myShells;
    }
}
