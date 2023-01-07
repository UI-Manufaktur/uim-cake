/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.Configure;

@safe:
import uim.cake;

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
     * @param string aKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param bool $checkExists Whether to check if file exists. Defaults to false.
     * @return string Full file path
     * @throws uim.cake.Core\exceptions.UIMException When files don"t exist or when
     *  files contain ".." as this could lead to abusive reads.
     */
    protected string _getFilePath(string aKey, bool $checkExists = false) {
        if (strpos($key, "..") != false) {
            throw new UIMException("Cannot load/dump configuration files with ../ in them.");
        }

        [$plugin, $key] = pluginSplit($key);

        if ($plugin) {
            $file = Plugin::configPath($plugin) . $key;
        } else {
            $file = _path . $key;
        }

        $file .= _extension;

        if (!$checkExists || is_file($file)) {
            return $file;
        }

        $realPath = realpath($file);
        if ($realPath != false && is_file($realPath)) {
            return $realPath;
        }

        throw new UIMException(sprintf("Could not load configuration file: %s", $file));
    }
}
