module uim.cake.core.Configure\Engine;

import uim.cake.core.Configure\IConfigEngine;
import uim.cake.core.Configure\FileConfigTrait;
import uim.cakeilities.Hash;

/**
 * Ini file configuration engine.
 *
 * Since IniConfig uses parse_ini_file underneath, you should be aware that this
 * class shares the same behavior, especially with regards to boolean and null values.
 *
 * In addition to the native `parse_ini_file` features, IniConfig also allows you
 * to create nested array structures through usage of `.` delimited names. This allows
 * you to create nested arrays structures in an ini config file. For example:
 *
 * `db.password = secret` would turn into `["db":["password":"secret"]]`
 *
 * You can nest properties as deeply as needed using `.`"s. In addition to using `.` you
 * can use standard ini section notation to create nested structures:
 *
 * ```
 * [section]
 * key = value
 * ```
 *
 * Once loaded into Configure, the above would be accessed using:
 *
 * `Configure::read("section.key");
 *
 * You can also use `.` separated values in section names to create more deeply
 * nested structures.
 *
 * IniConfig also manipulates how the special ini values of
 * "yes", "no", "on", "off", "null" are handled. These values will be
 * converted to their boolean equivalents.
 *
 * @see https://secure.php.net/parse_ini_file
 */
class IniConfig : IConfigEngine
{
    use FileConfigTrait;

    /**
     * File extension.
     */
    protected string $_extension = ".ini";

    /**
     * The section to read, if null all sections will be read.
     *
     * @var string|null
     */
    protected $_section;

    /**
     * Build and construct a new ini file parser. The parser can be used to read
     * ini files that are on the filesystem.
     *
     * @param string|null myPath Path to load ini config files from. Defaults to CONFIG.
     * @param string|null $section Only get one section, leave null to parse and fetch
     *     all sections in the ini file.
     */
    this(Nullable!string myPath = null, Nullable!string $section = null) {
        if (myPath == null) {
            myPath = CONFIG;
        }
        this._path = myPath;
        this._section = $section;
    }

    /**
     * Read an ini file and return the results as an array.
     *
     * @param string myKey The identifier to read from. If the key has a . it will be treated
     *  as a plugin prefix. The chosen file must be on the engine"s path.
     * @return array Parsed configuration values.
     * @throws \Cake\Core\Exception\CakeException when files don"t exist.
     *  Or when files contain ".." as this could lead to abusive reads.
     */
    function read(string myKey): array
    {
        myfile = this._getFilePath(myKey, true);

        myContentss = parse_ini_file(myfile, true);
        if (this._section && isset(myContentss[this._section])) {
            myValues = this._parseNestedValues(myContentss[this._section]);
        } else {
            myValues = [];
            foreach (myContentss as $section: $attribs) {
                if (is_array($attribs)) {
                    myValues[$section] = this._parseNestedValues($attribs);
                } else {
                    $parse = this._parseNestedValues([$attribs]);
                    myValues[$section] = array_shift($parse);
                }
            }
        }

        return myValues;
    }

    /**
     * parses nested values out of keys.
     *
     * @param array myValues Values to be exploded.
     * @return array Array of values exploded
     */
    protected auto _parseNestedValues(array myValues): array
    {
        foreach (myValues as myKey: myValue) {
            if (myValue == "1") {
                myValue = true;
            }
            if (myValue == "") {
                myValue = false;
            }
            unset(myValues[myKey]);
            if (strpos((string)myKey, ".") !== false) {
                myValues = Hash::insert(myValues, myKey, myValue);
            } else {
                myValues[myKey] = myValue;
            }
        }

        return myValues;
    }

    /**
     * Dumps the state of Configure data into an ini formatted string.
     *
     * @param string myKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param array myData The data to convert to ini file.
     * @return bool Success.
     */
    bool dump(string myKey, array myData) {
        myResult = [];
        foreach (myData as $k: myValue) {
            $isSection = false;
            /** @psalm-suppress InvalidArrayAccess */
            if ($k[0] !== "[") {
                myResult[] = "[$k]";
                $isSection = true;
            }
            if (is_array(myValue)) {
                $kValues = Hash::flatten(myValue, ".");
                foreach ($kValues as $k2: $v) {
                    myResult[] = "$k2 = " . this._value($v);
                }
            }
            if ($isSection) {
                myResult[] = "";
            }
        }
        myContentss = trim(implode("\n", myResult));

        myfilename = this._getFilePath(myKey);

        return file_put_contents(myfilename, myContentss) > 0;
    }

    /**
     * Converts a value into the ini equivalent
     *
     * @param mixed myValue Value to export.
     * @return string String value for ini file.
     */
    protected string _value(myValue) {
        if (myValue == null) {
            return "null";
        }
        if (myValue == true) {
            return "true";
        }
        if (myValue == false) {
            return "false";
        }

        return (string)myValue;
    }
}
