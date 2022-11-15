module uim.cake.console;

import uim.cakere.App;
import uim.cakere.Configure;
import uim.cakere.Plugin;
import uim.cakelesystem\Filesystem;
import uim.cakeilities.Inflector;

/**
 * Used by CommandCollection and CommandTask to scan the filesystem
 * for command classes.
 *
 * @internal
 */
class CommandScanner
{
    /**
     * Scan CakePHP internals for shells & commands.
     *
     * @return array A list of command metadata.
     */
    function scanCore(): array
    {
        $coreShells = this.scanDir(
            dirname(__DIR__) . DIRECTORY_SEPARATOR . "Shell" . DIRECTORY_SEPARATOR,
            "Cake\Shell\\",
            "",
            ["command_list"]
        );
        $coreCommands = this.scanDir(
            dirname(__DIR__) . DIRECTORY_SEPARATOR . "Command" . DIRECTORY_SEPARATOR,
            "Cake\Command\\",
            "",
            ["command_list"]
        );

        return array_merge($coreShells, $coreCommands);
    }

    /**
     * Scan the application for shells & commands.
     *
     * @return array A list of command metadata.
     */
    function scanApp(): array
    {
        $appmodule = Configure::read("App.module");
        $appShells = this.scanDir(
            App::classPath("Shell")[0],
            $appmodule . "\Shell\\",
            "",
            []
        );
        $appCommands = this.scanDir(
            App::classPath("Command")[0],
            $appmodule . "\Command\\",
            "",
            []
        );

        return array_merge($appShells, $appCommands);
    }

    /**
     * Scan the named plugin for shells and commands
     *
     * @param string myPlugin The named plugin.
     * @return array A list of command metadata.
     */
    function scanPlugin(string myPlugin): array
    {
        if (!Plugin::isLoaded(myPlugin)) {
            return [];
        }
        myPath = Plugin::classPath(myPlugin);
        $module = str_replace("/", "\\", myPlugin);
        $prefix = Inflector::underscore(myPlugin) . ".";

        $commands = this.scanDir(myPath . "Command", $module . "\Command\\", $prefix, []);
        myShells = this.scanDir(myPath . "Shell", $module . "\Shell\\", $prefix, []);

        return array_merge(myShells, $commands);
    }

    /**
     * Scan a directory for .php files and return the class names that
     * should be within them.
     *
     * @param string myPath The directory to read.
     * @param string $module The module the shells live in.
     * @param string $prefix The prefix to apply to commands for their full name.
     * @param array<string> $hide A list of command names to hide as they are internal commands.
     * @return array The list of shell info arrays based on scanning the filesystem and inflection.
     */
    protected auto scanDir(string myPath, string $module, string $prefix, array $hide): array
    {
        if (!is_dir(myPath)) {
            return [];
        }

        // This ensures `Command` class is not added to the list.
        $hide[] = "";

        myClassPattern = "/(Shell|Command)\.php$/";
        $fs = new Filesystem();
        /** @var array<\SplFileInfo> myfiles */
        myfiles = $fs.find(myPath, myClassPattern);

        myShells = [];
        foreach (myfiles as myfileInfo) {
            myfile = myfileInfo.getFilename();

            myName = Inflector::underscore(preg_replace(myClassPattern, "", myfile));
            if (in_array(myName, $hide, true)) {
                continue;
            }

            myClass = $module . myfileInfo.getBasename(".php");
            /** @psalm-suppress DeprecatedClass */
            if (
                !is_subclass_of(myClass, Shell::class)
                && !is_subclass_of(myClass, ICommand::class)
            ) {
                continue;
            }
            if (is_subclass_of(myClass, BaseCommand::class)) {
                myName = myClass::defaultName();
            }
            myShells[myPath . myfile] = [
                "file" => myPath . myfile,
                "fullName" => $prefix . myName,
                "name" => myName,
                "class" => myClass,
            ];
        }

        ksort(myShells);

        return array_values(myShells);
    }
}
