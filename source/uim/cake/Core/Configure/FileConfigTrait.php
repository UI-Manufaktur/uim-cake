


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.core.Configure;

import uim.cake.core.exceptions.CakeException;
import uim.cake.core.Plugin;

/**
 * Trait providing utility methods for file based config engines.
 */
trait FileConfigTrait
{
    /**
     * The path this engine finds files on.
     *
     * @var string
     */
    protected $_path = "";

    /**
     * Get file path
     *
     * @param string $key The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param bool $checkExists Whether to check if file exists. Defaults to false.
     * @return string Full file path
     * @throws uim.cake.Core\Exception\CakeException When files don"t exist or when
     *  files contain ".." as this could lead to abusive reads.
     */
    protected function _getFilePath(string $key, bool $checkExists = false): string
    {
        if (strpos($key, "..") != false) {
            throw new CakeException("Cannot load/dump configuration files with ../ in them.");
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

        throw new CakeException(sprintf("Could not load configuration file: %s", $file));
    }
}
