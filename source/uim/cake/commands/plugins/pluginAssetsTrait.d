module uim.cake.command;

import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cakelesystem\Filesystem;
import uim.cakeilities.Inflector;

/**
 * trait for symlinking / copying plugin assets to app"s webroot.
 *
 * @internal
 */
trait PluginAssetsTrait
{
    /**
     * Arguments
     *
     * @var uim.cake.consoles.Arguments
     */
    protected args;

    /**
     * Console IO
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected io;

    /**
     * Get list of plugins to process. Plugins without a webroot directory are skipped.
     *
     * @param string|null myName Name of plugin for which to symlink assets.
     *   If null all plugins will be processed.
     * @return array<string, mixed> List of plugins with meta data.
     */
    protected array _list(Nullable!string myName = null) {
        if (myName is null) {
            myPluginsList = Plugin::loaded();
        } else {
            myPluginsList = [myName];
        }

        myPlugins = [];

        foreach (myPlugin; myPluginsList) {
            myPath = Plugin::path(myPlugin) ~ "webroot";
            if (!is_dir(myPath)) {
                this.io.verbose("", 1);
                this.io.verbose(
                    sprintf("Skipping plugin %s. It does not have webroot folder.", myPlugin),
                    2
                );
                continue;
            }

            $link = Inflector::underscore(myPlugin);
            $wwwRoot = Configure::read("App.wwwRoot");
            $dir = $wwwRoot;
            $moduled = false;
            if (indexOf($link, "/") != false) {
                $moduled = true;
                $parts = explode("/", $link);
                $link = array_pop($parts);
                $dir = $wwwRoot . implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR;
            }

            myPlugins[myPlugin] = [
                "srcPath":Plugin::path(myPlugin) ~ "webroot",
                "destDir":$dir,
                "link":$link,
                "moduled":$moduled,
            ];
        }

        return myPlugins;
    }

    /**
     * Process plugins
     *
     * @param array<string, mixed> myPlugins List of plugins to process
     * @param bool shouldCopy Force copy mode. Default false.
     * @param bool shouldOverwrite Overwrite existing files.
     */
    protected void _process(array myPlugins, bool shouldCopy = false, bool shouldOverwrite = false) {
        foreach (myPlugin; myConfig; myPlugins) {
            this.io.out();
            this.io.out("For plugin: " ~ myPlugin);
            this.io.hr();

            if (
                myConfig["moduled"] &&
                !is_dir(myConfig["destDir"]) &&
                !_createDirectory(myConfig["destDir"])
            ) {
                continue;
            }

            auto myDestination = myConfig["destDir"] . myConfig["link"];
            if (file_exists(myDestination)) {
                if (shouldOverwrite && !_remove(myConfig)) {
                    continue;
                } elseif (!shouldOverwrite) {
                    this.io.verbose(
                        myDestination ~ " already exists",
                        1
                    );

                    continue;
                }
            }

            if (!shouldCopy) {
                myResult = _createSymlink(
                    myConfig["srcPath"],
                    myDestination
                );
                if (myResult) {
                    continue;
                }
            }

            _copyDirectory(
                myConfig["srcPath"],
                myDestination
            );
        }

        this.io.out();
        this.io.out("Done");
    }

    /**
     * Remove folder/symlink.
     *
     * @param array<string, mixed> myConfig Plugin config.
     */
    protected bool _remove(array myConfig) {
        if (myConfig["moduled"] && !is_dir(myConfig["destDir"])) {
            this.io.verbose(
                myConfig["destDir"] . myConfig["link"] ~ " does not exist",
                1
            );

            return false;
        }

        myDestination = myConfig["destDir"] . myConfig["link"];

        if (!file_exists(myDestination)) {
            this.io.verbose(
                myDestination ~ " does not exist",
                1
            );

            return false;
        }

        if (is_link(myDestination)) {
            // phpcs:ignore
            $success = DS == "\\" ? @rmdir(myDestination) : @unlink(myDestination);
            if ($success) {
                this.io.out("Unlinked " ~ myDestination);

                return true;
            } else {
                this.io.err("Failed to unlink  " ~ myDestination);

                return false;
            }
        }

        $fs = new Filesystem();
        if ($fs.deleteDir(myDestination)) {
            this.io.out("Deleted " ~ myDestination);

            return true;
        } else {
            this.io.err("Failed to delete " ~ myDestination);

            return false;
        }
    }

    /**
     * Create directory
     *
     * @param string dir Directory name
     */
    protected bool _createDirectory(string dir) {
        $old = umask(0);
        // phpcs:disable
        myResult = @mkdir($dir, 0755, true);
        // phpcs:enable
        umask($old);

        if (myResult) {
            this.io.out("Created directory " ~ $dir);

            return true;
        }

        this.io.err("Failed creating directory " ~ $dir);

        return false;
    }

    /**
     * Create symlink
     *
     * @param string myTarget Target directory
     * @param string link Link name
     */
    protected bool _createSymlink(string myTarget, string link) {
        // phpcs:disable
        myResult = @symlink(myTarget, $link);
        // phpcs:enable

        if (myResult) {
            this.io.out("Created symlink " ~ $link);

            return true;
        }

        return false;
    }

    /**
     * Copy directory
     *
     * @param string source Source directory
     * @param string myDestinationination Destination directory
     */
    protected bool _copyDirectory(string source, string myDestinationination) {
        $fs = new Filesystem();
        if ($fs.copyDir($source, myDestinationination)) {
            this.io.out("Copied assets to directory " ~ myDestinationination);

            return true;
        }

        this.io.err("Error copying assets to directory " ~ myDestinationination);

        return false;
    }
}
