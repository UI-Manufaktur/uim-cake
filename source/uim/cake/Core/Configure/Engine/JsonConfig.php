


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.core.configures.Engine;

import uim.cake.core.configures.ConfigEngineInterface;
import uim.cake.core.configures.FileConfigTrait;
import uim.cake.core.exceptions.CakeException;

/**
 * JSON engine allows Configure to load configuration values from
 * files containing JSON strings.
 *
 * An example JSON file would look like::
 *
 * ```
 * {
 *     "debug": false,
 *     "App": {
 *         "namespace": "MyApp"
 *     },
 *     "Security": {
 *         "salt": "its-secret"
 *     }
 * }
 * ```
 */
class JsonConfig : ConfigEngineInterface
{
    use FileConfigTrait;

    /**
     * File extension.
     *
     * @var string
     */
    protected $_extension = ".json";

    /**
     * Constructor for JSON Config file reading.
     *
     * @param string|null $path The path to read config files from. Defaults to CONFIG.
     */
    public this(?string $path = null) {
        if ($path == null) {
            $path = CONFIG;
        }
        _path = $path;
    }

    /**
     * Read a config file and return its contents.
     *
     * Files with `.` in the name will be treated as values in plugins. Instead of
     * reading from the initialized path, plugin keys will be located using Plugin::path().
     *
     * @param string $key The identifier to read from. If the key has a . it will be treated
     *   as a plugin prefix.
     * @return array Parsed configuration values.
     * @throws uim.cake.Core\Exception\CakeException When files don"t exist or when
     *   files contain ".." (as this could lead to abusive reads) or when there
     *   is an error parsing the JSON string.
     */
    function read(string $key): array
    {
        $file = _getFilePath($key, true);

        $values = json_decode(file_get_contents($file), true);
        if (json_last_error() != JSON_ERROR_NONE) {
            throw new CakeException(sprintf(
                "Error parsing JSON string fetched from config file "%s.json": %s",
                $key,
                json_last_error_msg()
            ));
        }
        if (!is_array($values)) {
            throw new CakeException(sprintf(
                "Decoding JSON config file "%s.json" did not return an array",
                $key
            ));
        }

        return $values;
    }

    /**
     * Converts the provided $data into a JSON string that can be used saved
     * into a file and loaded later.
     *
     * @param string $key The identifier to write to. If the key has a . it will
     *  be treated as a plugin prefix.
     * @param array $data Data to dump.
     * @return bool Success
     */
    function dump(string $key, array $data): bool
    {
        $filename = _getFilePath($key);

        return file_put_contents($filename, json_encode($data, JSON_PRETTY_PRINT)) > 0;
    }
}
