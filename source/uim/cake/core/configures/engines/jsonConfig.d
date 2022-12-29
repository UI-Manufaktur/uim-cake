module uim.cake.core.configures.Engine;

import uim.cake.core.configures.IConfigEngine;
import uim.cake.core.configures.FileConfigTrait;
import uim.cake.core.exceptions\CakeException;

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
 *         "module": "MyApp"
 *     },
 *     "Security": {
 *         "salt": "its-secret"
 *     }
 * }
 * ```
 */
class JsonConfig : IConfigEngine
{
    use FileConfigTrait;

    /**
     * File extension.
     */
    protected string _extension = ".json";

    /**
     * Constructor for JSON Config file reading.
     *
     * @param string|null myPath The path to read config files from. Defaults to CONFIG.
     */
    this(Nullable!string myPath = null) {
        if (myPath is null) {
            myPath = CONFIG;
        }
        _path = myPath;
    }

    /**
     * Read a config file and return its contents.
     *
     * Files with `.` in the name will be treated as values in plugins. Instead of
     * reading from the initialized path, plugin keys will be located using Plugin::path().
     *
     * @param string myKey The identifier to read from. If the key has a . it will be treated
     *   as a plugin prefix.
     * @return array Parsed configuration values.
     * @throws uim.cake.Core\exceptions.CakeException When files don"t exist or when
     *   files contain ".." (as this could lead to abusive reads) or when there
     *   is an error parsing the JSON string.
     */
    array read(string myKey) {
        myfile = _getFilePath(myKey, true);

        myValues = json_decode(file_get_contents(myfile), true);
        if (json_last_error() != JSON_ERROR_NONE) {
            throw new CakeException(sprintf(
                "Error parsing JSON string fetched from config file "%s.json": %s",
                myKey,
                json_last_error_msg()
            ));
        }
        if (!is_array(myValues)) {
            throw new CakeException(sprintf(
                "Decoding JSON config file "%s.json" did not return an array",
                myKey
            ));
        }

        return myValues;
    }

    /**
     * Converts the provided myData into a JSON string that can be used saved
     * into a file and loaded later.
     *
     * @param string myKey The identifier to write to. If the key has a . it will
     *  be treated as a plugin prefix.
     * @param array myData Data to dump.
     * @return bool Success
     */
    bool dump(string myKey, array myData) {
        myfilename = _getFilePath(myKey);

        return file_put_contents(myfilename, json_encode(myData, JSON_PRETTY_PRINT)) > 0;
    }
}
