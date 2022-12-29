module uim.cake.core.configures.Engine;

import uim.cake.core.configures.IConfigEngine;
import uim.cake.core.configures.FileConfigTrait;
import uim.cake.core.exceptions\CakeException;

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
 *     "debug":false,
 *     "Security":[
 *         "salt":"its-secret"
 *     ],
 *     "App":[
 *         "module":"App"
 *     ]
 * ];
 * ```
 *
 * @see uim.cake.Core\Configure::load() for how to load custom configuration files.
 */
class PhpConfig : IConfigEngine
{
    use FileConfigTrait;

    /**
     * File extension.
     */
    protected string _extension = ".php";

    /**
     * Constructor for PHP Config file reading.
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
     *  as a plugin prefix.
     * @return array Parsed configuration values.
     * @throws \Cake\Core\Exception\CakeException when files don"t exist or they don"t contain `myConfig`.
     *  Or when files contain ".." as this could lead to abusive reads.
     */
    array read(string myKey) {
        myfile = _getFilePath(myKey, true);

        myConfig = null;

        $return = include myfile;
        if (is_array($return)) {
            return $return;
        }

        throw new CakeException(sprintf("Config file "%s" did not return an array", myKey . ".php"));
    }

    /**
     * Converts the provided myData into a string of PHP code that can
     * be used saved into a file and loaded later.
     *
     * @param string myKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param array myData Data to dump.
     * @return bool Success
     */
    bool dump(string myKey, array myData) {
        myContentss = "<?php" . "\n" . "return " . var_export(myData, true) . ";";

        myfilename = _getFilePath(myKey);

        return file_put_contents(myfilename, myContentss) > 0;
    }
}
