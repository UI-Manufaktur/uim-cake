/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.classloader;

@safe:
  import uim.cake;

/**
 * ClassLoader
 *
 * @deprecated 4.0.3 Use composer to generate autoload files instead.
 */
class ClassLoader
{
    /**
     * An associative array where the key is a namespace prefix and the value
     * is an array of base directories for classes in that namespace.
     *
     * @var array<string, array>
     */
    protected _prefixes = null;

    /**
     * Register loader with SPL autoloader stack.
     */
    void register() {
        /** @var callable $callable */
        $callable = [this, "loadClass"];
        spl_autoload_register($callable);
    }

    /**
     * Adds a base directory for a namespace prefix.
     *
     * @param string $prefix The namespace prefix.
     * @param string $baseDir A base directory for class files in the
     * namespace.
     * @param bool $prepend If true, prepend the base directory to the stack
     * instead of appending it; this causes it to be searched first rather
     * than last.
     */
    void addNamespace(string $prefix, string $baseDir, bool $prepend = false) {
        $prefix = trim($prefix, "\\") ~ "\\";

        $baseDir = rtrim($baseDir, "/") . DIRECTORY_SEPARATOR;
        $baseDir = rtrim($baseDir, DIRECTORY_SEPARATOR) ~ "/";

        _prefixes[$prefix] = _prefixes[$prefix] ?? [];

        if ($prepend) {
            array_unshift(_prefixes[$prefix], $baseDir);
        } else {
            _prefixes[$prefix][] = $baseDir;
        }
    }

    /**
     * Loads the class file for a given class name.
     *
     * @param string $class The fully-qualified class name.
     * @return string|false The mapped file name on success, or boolean false on
     * failure.
     */
    function loadClass(string $class) {
        $prefix = $class;

        while (($pos = strrpos($prefix, "\\")) != false) {
            $prefix = substr($class, 0, $pos + 1);
            $relativeClass = substr($class, $pos + 1);

            $mappedFile = _loadMappedFile($prefix, $relativeClass);
            if ($mappedFile) {
                return $mappedFile;
            }

            $prefix = rtrim($prefix, "\\");
        }

        return false;
    }

    /**
     * Load the mapped file for a namespace prefix and relative class.
     *
     * @param string $prefix The namespace prefix.
     * @param string $relativeClass The relative class name.
     * @return string|false Boolean false if no mapped file can be loaded, or the
     * name of the mapped file that was loaded.
     */
    protected function _loadMappedFile(string $prefix, string $relativeClass) {
        if (!isset(_prefixes[$prefix])) {
            return false;
        }

        foreach (_prefixes[$prefix] as $baseDir) {
            $file = $baseDir . replace("\\", DIRECTORY_SEPARATOR, $relativeClass) ~ ".php";

            if (_requireFile($file)) {
                return $file;
            }
        }

        return false;
    }

    /**
     * If a file exists, require it from the file system.
     *
     * @param string $file The file to require.
     * @return bool True if the file exists, false if not.
     */
    protected bool _requireFile(string $file) {
        if (file_exists($file)) {
            require $file;

            return true;
        }

        return false;
    }
}
