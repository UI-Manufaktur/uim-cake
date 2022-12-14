module uim.cake.consoles;

import uim.cake.core.App;
import uim.cake.core.Configure;
import uim.cake.core.Plugin;
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
     * Scan UIM internals for shells & commands.
     *
     * @return array A list of command metadata.
     */
    array scanCore() array
    {
        $coreShells = this.scanDir(
            dirname(__DIR__) . DIRECTORY_SEPARATOR ~ "Shell" ~ DIRECTORY_SEPARATOR,
            "Cake\Shell\\",
            "",
            ["command_list"]
        );
        $coreCommands = this.scanDir(
            dirname(__DIR__) . DIRECTORY_SEPARATOR ~ "Command" ~ DIRECTORY_SEPARATOR,
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
    array scanApp() array
    {
        $appNamespace = Configure::read("App.namespace");
        $appShells = this.scanDir(
            App::classPath("Shell")[0],
            $appNamespace ~ "\Shell\\",
            "",
            []
        );
        $appCommands = this.scanDir(
            App::classPath("Command")[0],
            $appNamespace ~ "\Command\\",
            "",
            []
        );

        return array_merge($appShells, $appCommands);
    }

    /**
     * Scan the named plugin for shells and commands
     *
     * @param string $plugin The named plugin.
     * @return array A list of command metadata.
     */
    array scanPlugin(string $plugin) array
    {
        if (!Plugin::isLoaded($plugin)) {
            return [];
        }
        $path = Plugin::classPath($plugin);
        $namespace = replace("/", "\\", $plugin);
        $prefix = Inflector::underscore($plugin) ~ ".";

        $commands = this.scanDir($path ~ "Command", $namespace ~ "\Command\\", $prefix, []);
        $shells = this.scanDir($path ~ "Shell", $namespace ~ "\Shell\\", $prefix, []);

        return array_merge($shells, $commands);
    }

    /**
     * Scan a directory for .php files and return the class names that
     * should be within them.
     *
     * @param string $path The directory to read.
     * @param string aNamespace The namespace the shells live in.
     * @param string $prefix The prefix to apply to commands for their full name.
     * @param array<string> $hide A list of command names to hide as they are internal commands.
     * @return array The list of shell info arrays based on scanning the filesystem and inflection.
     */
    protected string[] scanDir(string $path, string aNamespace, string $prefix, array $hide) {
        if (!is_dir($path)) {
            return [];
        }

        // This ensures `Command` class is not added to the list.
        $hide[] = "";

        $classPattern = "/(Shell|Command)\.php$/";
        $fs = new Filesystem();
        /** @var array<\SplFileInfo> $files */
        $files = $fs.find($path, $classPattern);

        $shells = null;
        foreach ($files as $fileInfo) {
            $file = $fileInfo.getFilename();

            $name = Inflector::underscore(preg_replace($classPattern, "", $file));
            if (hasAllValues($name, $hide, true)) {
                continue;
            }

            $class = $namespace . $fileInfo.getBasename(".php");
            /** @psalm-suppress DeprecatedClass */
            if (
                !is_subclass_of($class, Shell::class)
                && !is_subclass_of($class, ICommand::class)
            ) {
                continue;
            }
            if (is_subclass_of($class, BaseCommand::class)) {
                $name = $class::defaultName();
            }
            $shells[$path . $file] = [
                "file": $path . $file,
                "fullName": $prefix . $name,
                "name": $name,
                "class": $class,
            ];
        }

        ksort($shells);

        return array_values($shells);
    }
}
