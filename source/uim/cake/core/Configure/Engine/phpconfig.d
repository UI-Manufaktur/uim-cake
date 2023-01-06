module uim.cake.core.configures.Engine;

import uim.cake.core.configures.ConfigEngineInterface;
import uim.cake.core.configures.FileConfigTrait;
import uim.cake.core.exceptions.CakeException;

/**
 * PHP engine allows Configure to load configuration values from
 * files containing simple PHP arrays.
 *
 * Files compatible with PhpConfig should return an array that
 * contains all the configuration data contained in the file.
 *
 * An example configuration file would look like::
 *
 * ```
 * <?php
 * return [
 *     "debug": false,
 *     "Security": [
 *         "salt": "its-secret"
 *     ],
 *     "App": [
 *         "namespace": "App"
 *     ]
 * ];
 * ```
 *
 * @see uim.cake.Core\Configure::load() for how to load custom configuration files.
 */
class PhpConfig : ConfigEngineInterface
{
    use FileConfigTrait;

    /**
     * File extension.
     */
    protected string _extension = ".php";

    /**
     * Constructor for PHP Config file reading.
     *
     * @param string|null $path The path to read config files from. Defaults to CONFIG.
     */
    this(Nullable!string $path = null) {
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
     * @param string aKey The identifier to read from. If the key has a . it will be treated
     *  as a plugin prefix.
     * @return array Parsed configuration values.
     * @throws uim.cake.Core\exceptions.CakeException when files don"t exist or they don"t contain `aConfig`.
     *  Or when files contain ".." as this could lead to abusive reads.
     */
    array read(string aKey) {
        $file = _getFilePath($key, true);

        aConfig = null;

        $return = include $file;
        if (is_array($return)) {
            return $return;
        }

        throw new CakeException(sprintf("Config file '%s' did not return an array", $key ~ ".php"));
    }

    /**
     * Converts the provided $data into a string of PHP code that can
     * be used saved into a file and loaded later.
     *
     * @param string aKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param array $data Data to dump.
     * @return bool Success
     */
    bool dump(string aKey, array $data) {
        $contents = "<?php" ~ "\n" ~ "return " ~ var_export($data, true) ~ ";";

        $filename = _getFilePath($key);

        return file_put_contents($filename, $contents) > 0;
    }
}
