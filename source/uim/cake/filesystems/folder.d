module uim.cake.filesystems;

use DirectoryIterator;
use Exception;
use InvalidArgumentException;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;

/**
 * Folder structure browser, lists folders and files.
 * Provides an Object interface for Common directory related tasks.
 *
 * @deprecated 4.0.0 Will be removed in 5.0.
 * @link https://book.UIM.org/4/en/core-libraries/file-folder.html#folder-api
 */
class Folder
{
    /**
     * Default scheme for Folder::copy
     * Recursively merges subfolders with the same name
     */
    const string MERGE = "merge";

    /**
     * Overwrite scheme for Folder::copy
     * subfolders with the same name will be replaced
     */
    const string OVERWRITE = "overwrite";

    /**
     * Skip scheme for Folder::copy
     * if a subfolder with the same name exists it will be skipped
     */
    const string SKIP = "skip";

    /**
     * Sort mode by name
     */
    const string SORT_NAME = "name";

    /**
     * Sort mode by time
     */
    const string SORT_TIME = "time";

    /**
     * Path to Folder.
     *
     * @var string
     */
    myPath;

    /**
     * Sortedness. Whether list results
     * should be sorted by name.
     *
     * @var bool
     */
    $sort = false;

    /**
     * Mode to be used on create. Does nothing on windows platforms.
     *
     * @var int
     * https://book.UIM.org/4/en/core-libraries/file-folder.html#Cake\filesystems.Folder::myMode
     */
    myMode = 0755;

    /**
     * Functions array to be called depending on the sort type chosen.
     *
     * @var array<string>
     */
    protected _fsorts = [
        self::SORT_NAME: "getPathname",
        self::SORT_TIME: "getCTime",
    ];

    /**
     * Holds messages from last method.
     *
     * @var array
     */
    protected _messages = [];

    /**
     * Holds errors from last method.
     *
     * @var array
     */
    protected _errors = [];

    /**
     * Holds array of complete directory paths.
     *
     * @var array
     */
    protected _directories;

    /**
     * Holds array of complete file paths.
     *
     * @var array
     */
    protected _files;

    /**
     * Constructor.
     *
     * @param string|null myPath Path to folder
     * @param bool $create Create folder if not found
     * @param int|null myMode Mode (CHMOD) to apply to created folder, false to ignore
     */
    this(Nullable!string myPath = null, bool $create = false, Nullable!int myMode = null) {
        if (empty(myPath)) {
            myPath = TMP;
        }
        if (myMode) {
            this.mode = myMode;
        }

        if (!file_exists(myPath) && $create == true) {
            this.create(myPath, this.mode);
        }
        if (!Folder::isAbsolute(myPath)) {
            myPath = realpath(myPath);
        }
        if (!empty(myPath)) {
            this.cd(myPath);
        }
    }

    /**
     * Return current path.
     *
     * @return string|null Current path
     */
    string pwd() {
        return this.path;
    }

    /**
     * Change directory to myPath.
     *
     * @param string myPath Path to the directory to change to
     * @return string|false The new path. Returns false on failure
     */
    function cd(string myPath) {
        myPath = this.realpath(myPath);
        if (myPath != false && is_dir(myPath)) {
            return this.path = myPath;
        }

        return false;
    }

    /**
     * Returns an array of the contents of the current directory.
     * The returned array holds two arrays: One of directories and one of files.
     *
     * @param string|bool $sort Whether you want the results sorted, set this and the sort property
     *   to false to get unsorted results.
     * @param array|bool myExceptions Either an array or boolean true will not grab dot files
     * @param bool $fullPath True returns the full path
     * @return array Contents of current directory as an array, an empty array on failure
     */
    function read($sort = self::SORT_NAME, myExceptions = false, bool $fullPath = false): array
    {
        $dirs = myfiles = [];

        if (!this.pwd()) {
            return [$dirs, myfiles];
        }
        if (is_array(myExceptions)) {
            myExceptions = array_flip(myExceptions);
        }
        $skipHidden = isset(myExceptions["."]) || myExceptions == true;

        try {
            $iterator = new DirectoryIterator(this.path);
        } catch (Exception $e) {
            return [$dirs, myfiles];
        }

        if (!is_bool($sort) && isset(_fsorts[$sort])) {
            $methodName = _fsorts[$sort];
        } else {
            $methodName = _fsorts[self::SORT_NAME];
        }

        foreach (myItem; $iterator) {
            if ($item.isDot()) {
                continue;
            }
            myName = $item.getFilename();
            if ($skipHidden && myName[0] == "." || isset(myExceptions[myName])) {
                continue;
            }
            if ($fullPath) {
                myName = $item.getPathname();
            }

            if ($item.isDir()) {
                $dirs[$item.{$methodName}()][] = myName;
            } else {
                myfiles[$item.{$methodName}()][] = myName;
            }
        }

        if ($sort || this.sort) {
            ksort($dirs);
            ksort(myfiles);
        }

        if ($dirs) {
            $dirs = array_merge(...array_values($dirs));
        }

        if (myfiles) {
            myfiles = array_merge(...array_values(myfiles));
        }

        return [$dirs, myfiles];
    }

    /**
     * Returns an array of all matching files in current directory.
     *
     * @param string regexpPattern Preg_match pattern (Defaults to: .*)
     * @param string|bool $sort Whether results should be sorted.
     * @return Files that match given pattern
     */
    string[] find(string regexpPattern = ".*", $sort = false) {
        [, myfiles] = this.read($sort);

        return array_values(preg_grep("/^" ~ $regexpPattern ~ "$/i", myfiles));
    }

    /**
     * Returns an array of all matching files in and below current directory.
     *
     * @param string pattern Preg_match pattern (Defaults to: .*)
     * @param string|bool $sort Whether results should be sorted.
     * @return array Files matching $pattern
     */
    function findRecursive(string pattern = ".*", $sort = false): array
    {
        if (!this.pwd()) {
            return [];
        }
        $startsOn = this.path;
        $out = _findRecursive($pattern, $sort);
        this.cd($startsOn);

        return $out;
    }

    /**
     * Private helper function for findRecursive.
     *
     * @param string pattern Pattern to match against
     * @param bool $sort Whether results should be sorted.
     * @return array Files matching pattern
     */
    protected auto _findRecursive(string pattern, bool $sort = false): array
    {
        [$dirs, myfiles] = this.read($sort);
        $found = [];

        foreach (myfiles as myfile) {
            if (preg_match("/^" ~ $pattern ~ "$/i", myfile)) {
                $found[] = Folder::addPathElement(this.path, myfile);
            }
        }
        $start = this.path;

        foreach ($dirs as $dir) {
            this.cd(Folder::addPathElement($start, $dir));
            $found = array_merge($found, this.findRecursive($pattern, $sort));
        }

        return $found;
    }

    /**
     * Returns true if given myPath is a Windows path.
     *
     * @param string myPath Path to check
     * @return bool true if windows path, false otherwise
     */
    static bool isWindowsPath(string myPath) {
        return preg_match("/^[A-Z]:\\\\/i", myPath) || substr(myPath, 0, 2) == "\\\\";
    }

    /**
     * Returns true if given myPath is an absolute path.
     *
     * @param string myPath Path to check
     * @return bool true if path is absolute.
     */
    static bool isAbsolute(string myPath) {
        if (empty(myPath)) {
            return false;
        }

        return myPath[0] == "/" ||
            preg_match("/^[A-Z]:\\\\/i", myPath) ||
            substr(myPath, 0, 2) == "\\\\" ||
            self::isRegisteredStreamWrapper(myPath);
    }

    /**
     * Returns true if given myPath is a registered stream wrapper.
     *
     * @param string myPath Path to check
     * @return bool True if path is registered stream wrapper.
     */
    static bool isRegisteredStreamWrapper(string myPath) {
        return preg_match("/^[^:\/]+?(?=:\/\/)/", myPath, $matches) &&
            in_array($matches[0], stream_get_wrappers(), true);
    }

    /**
     * Returns a correct set of slashes for given myPath. (\\ for Windows paths and / for other paths.)
     *
     * @param string myPath Path to transform
     * @return string Path with the correct set of slashes ("\\" or "/")
     */
    static string normalizeFullPath(string myPath) {
        $to = Folder::correctSlashFor(myPath);
        $from = ($to == "/" ? "\\" : "/");

        return str_replace($from, $to, myPath);
    }

    /**
     * Returns a correct set of slashes for given myPath. (\\ for Windows paths and / for other paths.)
     *
     * @param string myPath Path to check
     * @return string Set of slashes ("\\" or "/")
     */
    static string correctSlashFor(string myPath) {
        return Folder::isWindowsPath(myPath) ? "\\" : "/";
    }

    /**
     * Returns myPath with added terminating slash (corrected for Windows or other OS).
     *
     * @param string myPath Path to check
     * @return string Path with ending slash
     */
    static string slashTerm(string myPath) {
        if (Folder::isSlashTerm(myPath)) {
            return myPath;
        }

        return myPath . Folder::correctSlashFor(myPath);
    }

    /**
     * Returns myPath with $element added, with correct slash in-between.
     *
     * @param string myPath Path
     * @param array<string>|string element Element to add at end of path
     * @return string Combined path
     */
    static string addPathElement(string myPath, $element) {
        $element = (array)$element;
        array_unshift($element, rtrim(myPath, DIRECTORY_SEPARATOR));

        return implode(DIRECTORY_SEPARATOR, $element);
    }

    /**
     * Returns true if the Folder is in the given path.
     *
     * @param string myPath The absolute path to check that the current `pwd()` resides within.
     * @param bool $reverse Reverse the search, check if the given `myPath` resides within the current `pwd()`.
     * @return bool
     * @throws \InvalidArgumentException When the given `myPath` argument is not an absolute path.
     */
    bool inPath(string myPath, bool $reverse = false) {
        if (!Folder::isAbsolute(myPath)) {
            throw new InvalidArgumentException("The myPath argument is expected to be an absolute path.");
        }

        $dir = Folder::slashTerm(myPath);
        $current = Folder::slashTerm(this.pwd());

        if (!$reverse) {
            $return = preg_match("/^" ~ preg_quote($dir, "/") ~ "(.*)/", $current);
        } else {
            $return = preg_match("/^" ~ preg_quote($current, "/") ~ "(.*)/", $dir);
        }

        return (bool)$return;
    }

    /**
     * Change the mode on a directory structure recursively. This includes changing the mode on files as well.
     *
     * @param string myPath The path to chmod.
     * @param int|null myMode Octal value, e.g. 0755.
     * @param bool $recursive Chmod recursively, set to false to only change the current directory.
     * @param array<string> myExceptions Array of files, directories to skip.
     * @return bool Success.
     */
    bool chmod(string myPath, Nullable!int myMode = null, bool $recursive = true, array myExceptions = []) {
        if (!myMode) {
            myMode = this.mode;
        }

        if ($recursive == false && is_dir(myPath)) {
            // phpcs:disable
            if (@chmod(myPath, intval(myMode, 8))) {
                // phpcs:enable
                _messages[] = sprintf("%s changed to %s", myPath, myMode);

                return true;
            }

            _errors[] = sprintf("%s NOT changed to %s", myPath, myMode);

            return false;
        }

        if (is_dir(myPath)) {
            myPaths = this.tree(myPath);

            foreach (myPaths as myType) {
                foreach (myType as $fullpath) {
                    $check = explode(DIRECTORY_SEPARATOR, $fullpath);
                    myCount = count($check);

                    if (in_array($check[myCount - 1], myExceptions, true)) {
                        continue;
                    }

                    // phpcs:disable
                    if (@chmod($fullpath, intval(myMode, 8))) {
                        // phpcs:enable
                        _messages[] = sprintf("%s changed to %s", $fullpath, myMode);
                    } else {
                        _errors[] = sprintf("%s NOT changed to %s", $fullpath, myMode);
                    }
                }
            }

            if (empty(_errors)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns an array of subdirectories for the provided or current path.
     *
     * @param string|null myPath The directory path to get subdirectories for.
     * @param bool $fullPath Whether to return the full path or only the directory name.
     * @return array Array of subdirectories for the provided or current path.
     */
    function subdirectories(Nullable!string myPath = null, bool $fullPath = true): array
    {
        if (!myPath) {
            myPath = this.path;
        }
        $subdirectories = [];

        try {
            $iterator = new DirectoryIterator(myPath);
        } catch (Exception $e) {
            return [];
        }

        foreach (myItem; $iterator) {
            if (!$item.isDir() || $item.isDot()) {
                continue;
            }
            $subdirectories[] = $fullPath ? $item.getRealPath() : $item.getFilename();
        }

        return $subdirectories;
    }

    /**
     * Returns an array of nested directories and files in each directory
     *
     * @param string|null myPath the directory path to build the tree from
     * @param array|bool myExceptions Either an array of files/folder to exclude
     *   or boolean true to not grab dot files/folders
     * @param string|null myType either "file" or "dir". Null returns both files and directories
     * @return array Array of nested directories and files in each directory
     */
    function tree(Nullable!string myPath = null, myExceptions = false, Nullable!string myType = null): array
    {
        if (!myPath) {
            myPath = this.path;
        }
        myfiles = [];
        $directories = [myPath];

        if (is_array(myExceptions)) {
            myExceptions = array_flip(myExceptions);
        }
        $skipHidden = false;
        if (myExceptions == true) {
            $skipHidden = true;
        } elseif (isset(myExceptions["."])) {
            $skipHidden = true;
            unset(myExceptions["."]);
        }

        try {
            $directory = new RecursiveDirectoryIterator(
                myPath,
                RecursiveDirectoryIterator::KEY_AS_PATHNAME | RecursiveDirectoryIterator::CURRENT_AS_SELF
            );
            $iterator = new RecursiveIteratorIterator($directory, RecursiveIteratorIterator::SELF_FIRST);
        } catch (Exception $e) {
            unset($directory, $iterator);

            if (myType is null) {
                return [[], []];
            }

            return [];
        }

        /**
         * @var string itemPath
         * @var \RecursiveDirectoryIterator $fsIterator
         */
        foreach (myItem; $iteratorPath: $fsIterator) {
            if ($skipHidden) {
                $subPathName = $fsIterator.getSubPathname();
                if ($subPathName[0] == "." || indexOf($subPathName, DIRECTORY_SEPARATOR ~ ".") != false) {
                    unset($fsIterator);
                    continue;
                }
            }
            /** @var \FilesystemIterator $item */
            $item = $fsIterator.current();
            if (!empty(myExceptions) && isset(myExceptions[$item.getFilename()])) {
                unset($fsIterator, $item);
                continue;
            }

            if ($item.isFile()) {
                myfiles[] = $itemPath;
            } elseif ($item.isDir() && !$item.isDot()) {
                $directories[] = $itemPath;
            }

            // inner iterators need to be unset too in order for locks on parents to be released
            unset($fsIterator, $item);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directory, $iterator);

        if (myType is null) {
            return [$directories, myfiles];
        }
        if (myType == "dir") {
            return $directories;
        }

        return myfiles;
    }

    /**
     * Create a directory structure recursively.
     *
     * Can be used to create deep path structures like `/foo/bar/baz/shoe/horn`
     *
     * @param string myPathname The directory structure to create. Either an absolute or relative
     *   path. If the path is relative and exists in the process" cwd it will not be created.
     *   Otherwise relative paths will be prefixed with the current pwd().
     * @param int|null myMode octal value 0755
     * @return bool Returns TRUE on success, FALSE on failure
     */
    bool create(string myPathname, Nullable!int myMode = null) {
        if (is_dir(myPathname) || empty(myPathname)) {
            return true;
        }

        if (!self::isAbsolute(myPathname)) {
            myPathname = self::addPathElement(this.pwd(), myPathname);
        }

        if (!myMode) {
            myMode = this.mode;
        }

        if (is_file(myPathname)) {
            _errors[] = sprintf("%s is a file", myPathname);

            return false;
        }
        myPathname = rtrim(myPathname, DIRECTORY_SEPARATOR);
        $nextPathname = substr(myPathname, 0, strrpos(myPathname, DIRECTORY_SEPARATOR));

        if (this.create($nextPathname, myMode)) {
            if (!file_exists(myPathname)) {
                $old = umask(0);
                umask($old);
                if (mkdir(myPathname, myMode, true)) {
                    _messages[] = sprintf("%s created", myPathname);

                    return true;
                }
                _errors[] = sprintf("%s NOT created", myPathname);

                return false;
            }
        }

        return false;
    }

    /**
     * Returns the size in bytes of this Folder and its contents.
     *
     * @return int size in bytes of current folder
     */
    int dirsize() {
        $size = 0;
        $directory = Folder::slashTerm(this.path);
        $stack = [$directory];
        myCount = count($stack);
        for ($i = 0, $j = myCount; $i < $j; $i++) {
            if (is_file($stack[$i])) {
                $size += filesize($stack[$i]);
            } elseif (is_dir($stack[$i])) {
                $dir = dir($stack[$i]);
                if ($dir) {
                    while (($entry = $dir.read()) != false) {
                        if ($entry == "." || $entry == "..") {
                            continue;
                        }
                        $add = $stack[$i] . $entry;

                        if (is_dir($stack[$i] . $entry)) {
                            $add = Folder::slashTerm($add);
                        }
                        $stack[] = $add;
                    }
                    $dir.close();
                }
            }
            $j = count($stack);
        }

        return $size;
    }

    /**
     * Recursively Remove directories if the system allows.
     *
     * @param string|null myPath Path of directory to delete
     * @return bool Success
     */
    bool delete(Nullable!string myPath = null) {
        if (!myPath) {
            myPath = this.pwd();
        }
        if (!myPath) {
            return false;
        }
        myPath = Folder::slashTerm(myPath);
        if (is_dir(myPath)) {
            try {
                $directory = new RecursiveDirectoryIterator(myPath, RecursiveDirectoryIterator::CURRENT_AS_SELF);
                $iterator = new RecursiveIteratorIterator($directory, RecursiveIteratorIterator::CHILD_FIRST);
            } catch (Exception $e) {
                unset($directory, $iterator);

                return false;
            }

            foreach (myItem; $iterator) {
                myfilePath = $item.getPathname();
                if ($item.isFile() || $item.isLink()) {
                    // phpcs:disable
                    if (@unlink(myfilePath)) {
                        // phpcs:enable
                        _messages[] = sprintf("%s removed", myfilePath);
                    } else {
                        _errors[] = sprintf("%s NOT removed", myfilePath);
                    }
                } elseif ($item.isDir() && !$item.isDot()) {
                    // phpcs:disable
                    if (@rmdir(myfilePath)) {
                        // phpcs:enable
                        _messages[] = sprintf("%s removed", myfilePath);
                    } else {
                        _errors[] = sprintf("%s NOT removed", myfilePath);

                        unset($directory, $iterator, $item);

                        return false;
                    }
                }

                // inner iterators need to be unset too in order for locks on parents to be released
                unset($item);
            }

            // unsetting iterators helps releasing possible locks in certain environments,
            // which could otherwise make `rmdir()` fail
            unset($directory, $iterator);

            myPath = rtrim(myPath, DIRECTORY_SEPARATOR);
            // phpcs:disable
            if (@rmdir(myPath)) {
                // phpcs:enable
                _messages[] = sprintf("%s removed", myPath);
            } else {
                _errors[] = sprintf("%s NOT removed", myPath);

                return false;
            }
        }

        return true;
    }

    /**
     * Recursive directory copy.
     *
     * ### Options
     *
     * - `from` The directory to copy from, this will cause a cd() to occur, changing the results of pwd().
     * - `mode` The mode to copy the files/directories with as integer, e.g. 0775.
     * - `skip` Files/directories to skip.
     * - `scheme` Folder::MERGE, Folder::OVERWRITE, Folder::SKIP
     * - `recursive` Whether to copy recursively or not (default: true - recursive)
     *
     * @param string to The directory to copy to.
     * @param array<string, mixed> myOptions Array of options (see above).
     * @return bool Success.
     */
    bool copy(string to, array myOptions = []) {
        if (!this.pwd()) {
            return false;
        }
        myOptions += [
            "from":this.path,
            "mode":this.mode,
            "skip":[],
            "scheme":Folder::MERGE,
            "recursive":true,
        ];

        $fromDir = myOptions["from"];
        $toDir = $to;
        myMode = myOptions["mode"];

        if (!this.cd($fromDir)) {
            _errors[] = sprintf("%s not found", $fromDir);

            return false;
        }

        if (!is_dir($toDir)) {
            this.create($toDir, myMode);
        }

        if (!is_writable($toDir)) {
            _errors[] = sprintf("%s not writable", $toDir);

            return false;
        }

        myExceptions = array_merge([".", "..", ".svn"], myOptions["skip"]);
        // phpcs:disable
        if ($handle = @opendir($fromDir)) {
            // phpcs:enable
            while (($item = readdir($handle)) != false) {
                $to = Folder::addPathElement($toDir, $item);
                if ((myOptions["scheme"] != Folder::SKIP || !is_dir($to)) && !in_array($item, myExceptions, true)) {
                    $from = Folder::addPathElement($fromDir, $item);
                    if (is_file($from) && (!is_file($to) || myOptions["scheme"] != Folder::SKIP)) {
                        if (copy($from, $to)) {
                            chmod($to, intval(myMode, 8));
                            touch($to, filemtime($from));
                            _messages[] = sprintf("%s copied to %s", $from, $to);
                        } else {
                            _errors[] = sprintf("%s NOT copied to %s", $from, $to);
                        }
                    }

                    if (is_dir($from) && file_exists($to) && myOptions["scheme"] == Folder::OVERWRITE) {
                        this.delete($to);
                    }

                    if (is_dir($from) && myOptions["recursive"] == false) {
                        continue;
                    }

                    if (is_dir($from) && !file_exists($to)) {
                        $old = umask(0);
                        if (mkdir($to, myMode, true)) {
                            umask($old);
                            $old = umask(0);
                            chmod($to, myMode);
                            umask($old);
                            _messages[] = sprintf("%s created", $to);
                            myOptions = ["from":$from] + myOptions;
                            this.copy($to, myOptions);
                        } else {
                            _errors[] = sprintf("%s not created", $to);
                        }
                    } elseif (is_dir($from) && myOptions["scheme"] == Folder::MERGE) {
                        myOptions = ["from":$from] + myOptions;
                        this.copy($to, myOptions);
                    }
                }
            }
            closedir($handle);
        } else {
            return false;
        }

        return empty(_errors);
    }

    /**
     * Recursive directory move.
     *
     * ### Options
     *
     * - `from` The directory to copy from, this will cause a cd() to occur, changing the results of pwd().
     * - `mode` The mode to copy the files/directories with as integer, e.g. 0775.
     * - `skip` Files/directories to skip.
     * - `scheme` Folder::MERGE, Folder::OVERWRITE, Folder::SKIP
     * - `recursive` Whether to copy recursively or not (default: true - recursive)
     *
     * @param string to The directory to move to.
     * @param array<string, mixed> myOptions Array of options (see above).
     * @return bool Success
     */
    bool move(string to, array myOptions = []) {
        myOptions += ["from":this.path, "mode":this.mode, "skip":[], "recursive":true];

        if (this.copy($to, myOptions) && this.delete(myOptions["from"])) {
            return (bool)this.cd($to);
        }

        return false;
    }

    /**
     * get messages from latest method
     *
     * @param bool $reset Reset message stack after reading
     */
    array messages(bool $reset = true): array
    {
        myMessages = _messages;
        if ($reset) {
            _messages = [];
        }

        return myMessages;
    }

    /**
     * get error from latest method
     *
     * @param bool $reset Reset error stack after reading
     */
    array errors(bool $reset = true): array
    {
        myErrors = _errors;
        if ($reset) {
            _errors = [];
        }

        return myErrors;
    }

    /**
     * Get the real path (taking ".." and such into account)
     *
     * @param string myPath Path to resolve
     * @return string|false The resolved path
     */
    function realpath(myPath) {
        if (indexOf(myPath, "..") == false) {
            if (!Folder::isAbsolute(myPath)) {
                myPath = Folder::addPathElement(this.path, myPath);
            }

            return myPath;
        }
        myPath = str_replace("/", DIRECTORY_SEPARATOR, trim(myPath));
        $parts = explode(DIRECTORY_SEPARATOR, myPath);
        $newparts = [];
        $newpath = "";
        if (myPath[0] == DIRECTORY_SEPARATOR) {
            $newpath = DIRECTORY_SEPARATOR;
        }

        while (($part = array_shift($parts))  !is null) {
            if ($part == "." || $part == "") {
                continue;
            }
            if ($part == "..") {
                if (!empty($newparts)) {
                    array_pop($newparts);
                    continue;
                }

                return false;
            }
            $newparts[] = $part;
        }
        $newpath .= implode(DIRECTORY_SEPARATOR, $newparts);

        return Folder::slashTerm($newpath);
    }

    /**
     * Returns true if given myPath ends in a slash (i.e. is slash-terminated).
     *
     * @param string myPath Path to check
     * @return bool true if path ends with slash, false otherwise
     */
    static bool isSlashTerm(string myPath) {
        $lastChar = myPath[strlen(myPath) - 1];

        return $lastChar == "/" || $lastChar == "\\";
    }
}
