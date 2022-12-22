module uim.cake.core.Configure;

import uim.cake.core.exceptions\CakeException;
import uim.cake.core.Plugin;

/**
 * Trait providing utility methods for file based config engines.
 */
trait FileConfigTrait
{
    /**
     * The path this engine finds files on.
     */
    protected string _path = "";

    /**
     * Get file path
     *
     * @param string myKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param bool $checkExists Whether to check if file exists. Defaults to false.
     * @return  Full file path
     * @throws \Cake\Core\Exception\CakeException When files don"t exist or when
     *  files contain ".." as this could lead to abusive reads.
     */
    protected string _getFilePath(string myKey, bool $checkExists = false) {
        if (indexOf(myKey, "..") != false) {
            throw new CakeException("Cannot load/dump configuration files with ../ in them.");
        }

        [myPlugin, myKey] = pluginSplit(myKey);

        if (myPlugin) {
            myfile = Plugin::configPath(myPlugin) . myKey;
        } else {
            myfile = _path . myKey;
        }

        myfile .= _extension;

        if (!$checkExists || is_file(myfile)) {
            return myfile;
        }

        $realPath = realpath(myfile);
        if ($realPath != false && is_file($realPath)) {
            return $realPath;
        }

        throw new CakeException(sprintf("Could not load configuration file: %s", myfile));
    }
}
