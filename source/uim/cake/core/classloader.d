module uim.cakere;

/**
 * ClassLoader
 *
 * @deprecated 4.0.3 Use composer to generate autoload files instead.
 */
class ClassLoader
{
    /**
     * An associative array where the key is a module prefix and the value
     * is an array of base directories for classes in that module.
     *
     * @var array<string, array>
     */
    protected $_prefixes = [];

    /**
     * Register loader with SPL autoloader stack.
     *
     * @return void
     */
    function register(): void
    {
        /** @var callable $callable */
        $callable = [this, 'loadClass'];
        spl_autoload_register($callable);
    }

    /**
     * Adds a base directory for a module prefix.
     *
     * @param string $prefix The module prefix.
     * @param string $baseDir A base directory for class files in the
     * module.
     * @param bool $prepend If true, prepend the base directory to the stack
     * instead of appending it; this causes it to be searched first rather
     * than last.
     * @return void
     */
    function addmodule(string $prefix, string $baseDir, bool $prepend = false): void
    {
        $prefix = trim($prefix, '\\') . '\\';

        $baseDir = rtrim($baseDir, '/') . DIRECTORY_SEPARATOR;
        $baseDir = rtrim($baseDir, DIRECTORY_SEPARATOR) . '/';

        this._prefixes[$prefix] = this._prefixes[$prefix] ?? [];

        if ($prepend) {
            array_unshift(this._prefixes[$prefix], $baseDir);
        } else {
            this._prefixes[$prefix][] = $baseDir;
        }
    }

    /**
     * Loads the class file for a given class name.
     *
     * @param string myClass The fully-qualified class name.
     * @return string|false The mapped file name on success, or boolean false on
     * failure.
     */
    function loadClass(string myClass) {
        $prefix = myClass;

        while (($pos = strrpos($prefix, '\\')) !== false) {
            $prefix = substr(myClass, 0, $pos + 1);
            $relativeClass = substr(myClass, $pos + 1);

            $mappedFile = this._loadMappedFile($prefix, $relativeClass);
            if ($mappedFile) {
                return $mappedFile;
            }

            $prefix = rtrim($prefix, '\\');
        }

        return false;
    }

    /**
     * Load the mapped file for a module prefix and relative class.
     *
     * @param string $prefix The module prefix.
     * @param string $relativeClass The relative class name.
     * @return string|false Boolean false if no mapped file can be loaded, or the
     * name of the mapped file that was loaded.
     */
    protected auto _loadMappedFile(string $prefix, string $relativeClass) {
        if (!isset(this._prefixes[$prefix])) {
            return false;
        }

        foreach (this._prefixes[$prefix] as $baseDir) {
            myfile = $baseDir . str_replace('\\', DIRECTORY_SEPARATOR, $relativeClass) . '.php';

            if (this._requireFile(myfile)) {
                return myfile;
            }
        }

        return false;
    }

    /**
     * If a file exists, require it from the file system.
     *
     * @param string myfile The file to require.
     * @return bool True if the file exists, false if not.
     */
    protected bool _requireFile(string myfile) {
        if (file_exists(myfile)) {
            require myfile;

            return true;
        }

        return false;
    }
}
