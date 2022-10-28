module uim.cake.command;

import uim.cake.core.Configure;
import uim.cake.core.Plugin;
import uim.cake.Filesystem\Filesystem;
import uim.cake.Utility\Inflector;

/**
 * trait for symlinking / copying plugin assets to app's webroot.
 *
 * @internal
 */
trait PluginAssetsTrait
{
    /**
     * Arguments
     *
     * @var \Cake\Console\Arguments
     */
    protected $args;

    /**
     * Console IO
     *
     * @var \Cake\Console\ConsoleIo
     */
    protected $io;

    /**
     * Get list of plugins to process. Plugins without a webroot directory are skipped.
     *
     * @param string|null myName Name of plugin for which to symlink assets.
     *   If null all plugins will be processed.
     * @return array<string, mixed> List of plugins with meta data.
     */
    protected auto _list(?string myName = null): array
    {
        if (myName === null) {
            myPluginsList = Plugin::loaded();
        } else {
            myPluginsList = [myName];
        }

        myPlugins = [];

        foreach (myPluginsList as myPlugin) {
            myPath = Plugin::path(myPlugin) . 'webroot';
            if (!is_dir(myPath)) {
                this.io.verbose('', 1);
                this.io.verbose(
                    sprintf('Skipping plugin %s. It does not have webroot folder.', myPlugin),
                    2
                );
                continue;
            }

            $link = Inflector::underscore(myPlugin);
            $wwwRoot = Configure::read('App.wwwRoot');
            $dir = $wwwRoot;
            $moduled = false;
            if (strpos($link, '/') !== false) {
                $moduled = true;
                $parts = explode('/', $link);
                $link = array_pop($parts);
                $dir = $wwwRoot . implode(DIRECTORY_SEPARATOR, $parts) . DIRECTORY_SEPARATOR;
            }

            myPlugins[myPlugin] = [
                'srcPath' => Plugin::path(myPlugin) . 'webroot',
                'destDir' => $dir,
                'link' => $link,
                'moduled' => $moduled,
            ];
        }

        return myPlugins;
    }

    /**
     * Process plugins
     *
     * @param array<string, mixed> myPlugins List of plugins to process
     * @param bool $copy Force copy mode. Default false.
     * @param bool $overwrite Overwrite existing files.
     * @return void
     */
    protected void _process(array myPlugins, bool $copy = false, bool $overwrite = false)
    {
        foreach (myPlugins as myPlugin => myConfig) {
            this.io.out();
            this.io.out('For plugin: ' . myPlugin);
            this.io.hr();

            if (
                myConfig['moduled'] &&
                !is_dir(myConfig['destDir']) &&
                !this._createDirectory(myConfig['destDir'])
            ) {
                continue;
            }

            $dest = myConfig['destDir'] . myConfig['link'];

            if (file_exists($dest)) {
                if ($overwrite && !this._remove(myConfig)) {
                    continue;
                } elseif (!$overwrite) {
                    this.io.verbose(
                        $dest . ' already exists',
                        1
                    );

                    continue;
                }
            }

            if (!$copy) {
                myResult = this._createSymlink(
                    myConfig['srcPath'],
                    $dest
                );
                if (myResult) {
                    continue;
                }
            }

            this._copyDirectory(
                myConfig['srcPath'],
                $dest
            );
        }

        this.io.out();
        this.io.out('Done');
    }

    /**
     * Remove folder/symlink.
     *
     * @param array<string, mixed> myConfig Plugin config.
     * @return bool
     */
    protected bool _remove(array myConfig) {
        if (myConfig['moduled'] && !is_dir(myConfig['destDir'])) {
            this.io.verbose(
                myConfig['destDir'] . myConfig['link'] . ' does not exist',
                1
            );

            return false;
        }

        $dest = myConfig['destDir'] . myConfig['link'];

        if (!file_exists($dest)) {
            this.io.verbose(
                $dest . ' does not exist',
                1
            );

            return false;
        }

        if (is_link($dest)) {
            // phpcs:ignore
            $success = DS === '\\' ? @rmdir($dest) : @unlink($dest);
            if ($success) {
                this.io.out('Unlinked ' . $dest);

                return true;
            } else {
                this.io.err('Failed to unlink  ' . $dest);

                return false;
            }
        }

        $fs = new Filesystem();
        if ($fs.deleteDir($dest)) {
            this.io.out('Deleted ' . $dest);

            return true;
        } else {
            this.io.err('Failed to delete ' . $dest);

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
        myResult = @mkdir($dir, 0755, true);
        // phpcs:enable
        umask($old);

        if (myResult) {
            this.io.out('Created directory ' . $dir);

            return true;
        }

        this.io.err('Failed creating directory ' . $dir);

        return false;
    }

    /**
     * Create symlink
     *
     * @param string myTarget Target directory
     * @param string $link Link name
     * @return bool
     */
    protected bool _createSymlink(string myTarget, string $link) {
        // phpcs:disable
        myResult = @symlink(myTarget, $link);
        // phpcs:enable

        if (myResult) {
            this.io.out('Created symlink ' . $link);

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
            this.io.out('Copied assets to directory ' . $destination);

            return true;
        }

        this.io.err('Error copying assets to directory ' . $destination);

        return false;
    }
}
