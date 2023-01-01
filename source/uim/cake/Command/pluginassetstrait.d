module uim.cake.commands;

import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cake.filesystems.Filesystem;
import uim.cake.utilities.Inflector;

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
    protected $args;

    /**
     * Console IO
     *
     * @var uim.cake.consoles.ConsoleIo
     */
    protected $io;

    /**
     * Get list of plugins to process. Plugins without a webroot directory are skipped.
     *
     * @param string|null $name Name of plugin for which to symlink assets.
     *   If null all plugins will be processed.
     * @return array<string, mixed> List of plugins with meta data.
     */
    protected function _list(?string aName = null): array
    {
        if ($name == null) {
            $pluginsList = Plugin::loaded();
        } else {
            $pluginsList = [$name];
        }

        $plugins = [];

        foreach ($pluginsList as $plugin) {
            $path = Plugin::path($plugin) ~ "webroot";
            if (!is_dir($path)) {
                this.io.verbose("", 1);
                this.io.verbose(
                    sprintf("Skipping plugin %s. It does not have webroot folder.", $plugin),
                    2
                );
                continue;
            }

            $link = Inflector::underscore($plugin);
            $wwwRoot = Configure::read("App.wwwRoot");
            $dir = $wwwRoot;
            $namespaced = false;
            if (strpos($link, "/") != false) {
                $namespaced = true;
                $parts = explode("/", $link);
                $link = array_pop($parts);
                $dir = $wwwRoot . implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR;
            }

            $plugins[$plugin] = [
                "srcPath": Plugin::path($plugin) ~ "webroot",
                "destDir": $dir,
                "link": $link,
                "namespaced": $namespaced,
            ];
        }

        return $plugins;
    }

    /**
     * Process plugins
     *
     * @param array<string, mixed> $plugins List of plugins to process
     * @param bool $copy Force copy mode. Default false.
     * @param bool $overwrite Overwrite existing files.
     */
    protected void _process(array $plugins, bool $copy = false, bool $overwrite = false) {
        foreach ($plugins as $plugin: $config) {
            this.io.out();
            this.io.out("For plugin: " ~ $plugin);
            this.io.hr();

            if (
                $config["namespaced"] &&
                !is_dir($config["destDir"]) &&
                !_createDirectory($config["destDir"])
            ) {
                continue;
            }

            $dest = $config["destDir"] . $config["link"];

            if (file_exists($dest)) {
                if ($overwrite && !_remove($config)) {
                    continue;
                } elseif (!$overwrite) {
                    this.io.verbose(
                        $dest ~ " already exists",
                        1
                    );

                    continue;
                }
            }

            if (!$copy) {
                $result = _createSymlink(
                    $config["srcPath"],
                    $dest
                );
                if ($result) {
                    continue;
                }
            }

            _copyDirectory(
                $config["srcPath"],
                $dest
            );
        }

        this.io.out();
        this.io.out("Done");
    }

    /**
     * Remove folder/symlink.
     *
     * @param array<string, mixed> $config Plugin config.
     * @return bool
     */
    protected bool _remove(array $config) {
        if ($config["namespaced"] && !is_dir($config["destDir"])) {
            this.io.verbose(
                $config["destDir"] . $config["link"] ~ " does not exist",
                1
            );

            return false;
        }

        $dest = $config["destDir"] . $config["link"];

        if (!file_exists($dest)) {
            this.io.verbose(
                $dest ~ " does not exist",
                1
            );

            return false;
        }

        if (is_link($dest)) {
            // phpcs:ignore
            $success = DS == "\\" ? @rmdir($dest) : @unlink($dest);
            if ($success) {
                this.io.out("Unlinked " ~ $dest);

                return true;
            } else {
                this.io.err("Failed to unlink  " ~ $dest);

                return false;
            }
        }

        $fs = new Filesystem();
        if ($fs.deleteDir($dest)) {
            this.io.out("Deleted " ~ $dest);

            return true;
        } else {
            this.io.err("Failed to delete " ~ $dest);

            return false;
        }
    }

    /**
     * Create directory
     *
     * @param string $dir Directory name
     * @return bool
     */
    protected bool _createDirectory(string $dir) {
        $old = umask(0);
        // phpcs:disable
        $result = @mkdir($dir, 0755, true);
        // phpcs:enable
        umask($old);

        if ($result) {
            this.io.out("Created directory " ~ $dir);

            return true;
        }

        this.io.err("Failed creating directory " ~ $dir);

        return false;
    }

    /**
     * Create symlink
     *
     * @param string $target Target directory
     * @param string $link Link name
     * @return bool
     */
    protected bool _createSymlink(string $target, string $link) {
        // phpcs:disable
        $result = @symlink($target, $link);
        // phpcs:enable

        if ($result) {
            this.io.out("Created symlink " ~ $link);

            return true;
        }

        return false;
    }

    /**
     * Copy directory
     *
     * @param string $source Source directory
     * @param string $destination Destination directory
     * @return bool
     */
    protected bool _copyDirectory(string $source, string $destination) {
        $fs = new Filesystem();
        if ($fs.copyDir($source, $destination)) {
            this.io.out("Copied assets to directory " ~ $destination);

            return true;
        }

        this.io.err("Error copying assets to directory " ~ $destination);

        return false;
    }
}