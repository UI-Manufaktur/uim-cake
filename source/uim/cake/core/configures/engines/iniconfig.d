module uim.cake.core.configures.Engine;

@safe:
import uim.cake;

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
 * `db.password = secret` would turn into `["db": ["password": "secret"]]`
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
class IniConfig : ConfigEngineInterface
{
    use FileConfigTrait;

    /**
     * File extension.
     */
    protected string _extension = ".ini";

    /**
     * The section to read, if null all sections will be read.
     *
     */
    protected Nullable!string _section;

    /**
     * Build and construct a new ini file parser. The parser can be used to read
     * ini files that are on the filesystem.
     *
     * @param string|null $path Path to load ini config files from. Defaults to CONFIG.
     * @param string|null $section Only get one section, leave null to parse and fetch
     *     all sections in the ini file.
     */
    this(Nullable!string $path = null, Nullable!string $section = null) {
        if ($path == null) {
            $path = CONFIG;
        }
        _path = $path;
        _section = $section;
    }

    /**
     * Read an ini file and return the results as an array.
     *
     * @param string aKey The identifier to read from. If the key has a . it will be treated
     *  as a plugin prefix. The chosen file must be on the engine"s path.
     * @return array Parsed configuration values.
     * @throws uim.cake.Core\exceptions.UIMException when files don"t exist.
     *  Or when files contain ".." as this could lead to abusive reads.
     */
    array read(string aKey) {
        $file = _getFilePath($key, true);

        $contents = parse_ini_file($file, true);
        if (_section && isset($contents[_section])) {
            $values = _parseNestedValues($contents[_section]);
        } else {
            $values = null;
            foreach ($contents as $section: $attribs) {
                if (is_array($attribs)) {
                    $values[$section] = _parseNestedValues($attribs);
                } else {
                    $parse = _parseNestedValues([$attribs]);
                    $values[$section] = array_shift($parse);
                }
            }
        }

        return $values;
    }

    /**
     * parses nested values out of keys.
     *
     * @param array $values Values to be exploded.
     * @return array Array of values exploded
     */
    protected array _parseNestedValues(array $values) {
        foreach ($values as $key: $value) {
            if ($value == "1") {
                $value = true;
            }
            if ($value == "") {
                $value = false;
            }
            unset($values[$key]);
            if (strpos((string)$key, ".") != false) {
                $values = Hash::insert($values, $key, $value);
            } else {
                $values[$key] = $value;
            }
        }

        return $values;
    }

    /**
     * Dumps the state of Configure data into an ini formatted string.
     *
     * @param string aKey The identifier to write to. If the key has a . it will be treated
     *  as a plugin prefix.
     * @param array $data The data to convert to ini file.
     * @return bool Success.
     */
    bool dump(string aKey, array $data) {
        $result = null;
        foreach ($data as $k: $value) {
            $isSection = false;
            /** @psalm-suppress InvalidArrayAccess */
            if ($k[0] != "[") {
                $result[] = "[$k]";
                $isSection = true;
            }
            if (is_array($value)) {
                $kValues = Hash::flatten($value, ".");
                foreach ($kValues as $k2: $v) {
                    $result[] = "$k2 = " ~ _value($v);
                }
            }
            if ($isSection) {
                $result[] = "";
            }
        }
        $contents = trim(implode("\n", $result));

        $filename = _getFilePath($key);

        return file_put_contents($filename, $contents) > 0;
    }

    /**
     * Converts a value into the ini equivalent
     *
     * @param mixed $value Value to export.
     * @return string String value for ini file.
     */
    protected string _value($value) {
        if ($value == null) {
            return "null";
        }
        if ($value == true) {
            return "true";
        }
        if ($value == false) {
            return "false";
        }

        return (string)$value;
    }
}
