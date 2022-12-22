<?php
declare(strict_types=1);

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.2.9
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
namespace Cake\Filesystem;

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
 * @link https://book.cakephp.org/4/en/core-libraries/file-folder.html#folder-api
 */
class Folder
{
    /**
     * Default scheme for Folder::copy
     * Recursively merges subfolders with the same name
     *
     * @var string
     */
    public const MERGE = 'merge';

    /**
     * Overwrite scheme for Folder::copy
     * subfolders with the same name will be replaced
     *
     * @var string
     */
    public const OVERWRITE = 'overwrite';

    /**
     * Skip scheme for Folder::copy
     * if a subfolder with the same name exists it will be skipped
     *
     * @var string
     */
    public const SKIP = 'skip';

    /**
     * Sort mode by name
     *
     * @var string
     */
    public const SORT_NAME = 'name';

    /**
     * Sort mode by time
     *
     * @var string
     */
    public const SORT_TIME = 'time';

    /**
     * Path to Folder.
     *
     * @var string
     */
    public $path;

    /**
     * Sortedness. Whether list results
     * should be sorted by name.
     *
     * @var bool
     */
    public $sort = false;

    /**
     * Mode to be used on create. Does nothing on windows platforms.
     *
     * @var int
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\Folder::$mode
     */
    public $mode = 0755;

    /**
     * Functions array to be called depending on the sort type chosen.
     *
     * @var array<string>
     */
    protected $_fsorts = [
        self::SORT_NAME => 'getPathname',
        self::SORT_TIME => 'getCTime',
    ];

    /**
     * Holds messages from last method.
     *
     * @var array
     */
    protected $_messages = [];

    /**
     * Holds errors from last method.
     *
     * @var array
     */
    protected $_errors = [];

    /**
     * Holds array of complete directory paths.
     *
     * @var array
     */
    protected $_directories;

    /**
     * Holds array of complete file paths.
     *
     * @var array
     */
    protected $_files;

    /**
     * Constructor.
     *
     * @param string|null $path Path to folder
     * @param bool $create Create folder if not found
     * @param int|null $mode Mode (CHMOD) to apply to created folder, false to ignore
     */
    public this(?string $path = null, bool $create = false, ?int $mode = null)
    {
        if (empty($path)) {
            $path = TMP;
        }
        if ($mode) {
            this->mode = $mode;
        }

        if (!file_exists($path) && $create == true) {
            this->create($path, this->mode);
        }
        if (!Folder::isAbsolute($path)) {
            $path = realpath($path);
        }
        if (!empty($path)) {
            this->cd($path);
        }
    }

    /**
     * Return current path.
     *
     * @return string|null Current path
     */
    function pwd(): ?string
    {
        return this->path;
    }

    /**
     * Change directory to $path.
     *
     * @param string $path Path to the directory to change to
     * @return string|false The new path. Returns false on failure
     */
    function cd(string $path)
    {
        $path = this->realpath($path);
        if ($path != false && is_dir($path)) {
            return this->path = $path;
        }

        return false;
    }

    /**
     * Returns an array of the contents of the current directory.
     * The returned array holds two arrays: One of directories and one of files.
     *
     * @param string|bool $sort Whether you want the results sorted, set this and the sort property
     *   to false to get unsorted results.
     * @param array|bool $exceptions Either an array or boolean true will not grab dot files
     * @param bool $fullPath True returns the full path
     * @return array Contents of current directory as an array, an empty array on failure
     */
    function read($sort = self::SORT_NAME, $exceptions = false, bool $fullPath = false): array
    {
        $dirs = $files = [];

        if (!this->pwd()) {
            return [$dirs, $files];
        }
        if (is_array($exceptions)) {
            $exceptions = array_flip($exceptions);
        }
        $skipHidden = isset($exceptions['.']) || $exceptions == true;

        try {
            $iterator = new DirectoryIterator(this->path);
        } catch (Exception $e) {
            return [$dirs, $files];
        }

        if (!is_bool($sort) && isset(this->_fsorts[$sort])) {
            $methodName = this->_fsorts[$sort];
        } else {
            $methodName = this->_fsorts[self::SORT_NAME];
        }

        foreach ($iterator as $item) {
            if ($item->isDot()) {
                continue;
            }
            $name = $item->getFilename();
            if ($skipHidden && $name[0] == '.' || isset($exceptions[$name])) {
                continue;
            }
            if ($fullPath) {
                $name = $item->getPathname();
            }

            if ($item->isDir()) {
                $dirs[$item->{$methodName}()][] = $name;
            } else {
                $files[$item->{$methodName}()][] = $name;
            }
        }

        if ($sort || this->sort) {
            ksort($dirs);
            ksort($files);
        }

        if ($dirs) {
            $dirs = array_merge(...array_values($dirs));
        }

        if ($files) {
            $files = array_merge(...array_values($files));
        }

        return [$dirs, $files];
    }

    /**
     * Returns an array of all matching files in current directory.
     *
     * @param string $regexpPattern Preg_match pattern (Defaults to: .*)
     * @param string|bool $sort Whether results should be sorted.
     * @return array<string> Files that match given pattern
     */
    function find(string $regexpPattern = '.*', $sort = false): array
    {
        [, $files] = this->read($sort);

        return array_values(preg_grep('/^' . $regexpPattern . '$/i', $files));
    }

    /**
     * Returns an array of all matching files in and below current directory.
     *
     * @param string $pattern Preg_match pattern (Defaults to: .*)
     * @param string|bool $sort Whether results should be sorted.
     * @return array Files matching $pattern
     */
    function findRecursive(string $pattern = '.*', $sort = false): array
    {
        if (!this->pwd()) {
            return [];
        }
        $startsOn = this->path;
        $out = this->_findRecursive($pattern, $sort);
        this->cd($startsOn);

        return $out;
    }

    /**
     * Private helper function for findRecursive.
     *
     * @param string $pattern Pattern to match against
     * @param bool $sort Whether results should be sorted.
     * @return array Files matching pattern
     */
    protected function _findRecursive(string $pattern, bool $sort = false): array
    {
        [$dirs, $files] = this->read($sort);
        $found = [];

        foreach ($files as $file) {
            if (preg_match('/^' . $pattern . '$/i', $file)) {
                $found[] = Folder::addPathElement(this->path, $file);
            }
        }
        $start = this->path;

        foreach ($dirs as $dir) {
            this->cd(Folder::addPathElement($start, $dir));
            $found = array_merge($found, this->findRecursive($pattern, $sort));
        }

        return $found;
    }

    /**
     * Returns true if given $path is a Windows path.
     *
     * @param string $path Path to check
     * @return bool true if windows path, false otherwise
     */
    public static function isWindowsPath(string $path): bool
    {
        return preg_match('/^[A-Z]:\\\\/i', $path) || substr($path, 0, 2) == '\\\\';
    }

    /**
     * Returns true if given $path is an absolute path.
     *
     * @param string $path Path to check
     * @return bool true if path is absolute.
     */
    public static function isAbsolute(string $path): bool
    {
        if (empty($path)) {
            return false;
        }

        return $path[0] == '/' ||
            preg_match('/^[A-Z]:\\\\/i', $path) ||
            substr($path, 0, 2) == '\\\\' ||
            self::isRegisteredStreamWrapper($path);
    }

    /**
     * Returns true if given $path is a registered stream wrapper.
     *
     * @param string $path Path to check
     * @return bool True if path is registered stream wrapper.
     */
    public static function isRegisteredStreamWrapper(string $path): bool
    {
        return preg_match('/^[^:\/]+?(?=:\/\/)/', $path, $matches) &&
            in_array($matches[0], stream_get_wrappers(), true);
    }

    /**
     * Returns a correct set of slashes for given $path. (\\ for Windows paths and / for other paths.)
     *
     * @param string $path Path to transform
     * @return string Path with the correct set of slashes ("\\" or "/")
     */
    public static function normalizeFullPath(string $path): string
    {
        $to = Folder::correctSlashFor($path);
        $from = ($to == '/' ? '\\' : '/');

        return str_replace($from, $to, $path);
    }

    /**
     * Returns a correct set of slashes for given $path. (\\ for Windows paths and / for other paths.)
     *
     * @param string $path Path to check
     * @return string Set of slashes ("\\" or "/")
     */
    public static function correctSlashFor(string $path): string
    {
        return Folder::isWindowsPath($path) ? '\\' : '/';
    }

    /**
     * Returns $path with added terminating slash (corrected for Windows or other OS).
     *
     * @param string $path Path to check
     * @return string Path with ending slash
     */
    public static function slashTerm(string $path): string
    {
        if (Folder::isSlashTerm($path)) {
            return $path;
        }

        return $path . Folder::correctSlashFor($path);
    }

    /**
     * Returns $path with $element added, with correct slash in-between.
     *
     * @param string $path Path
     * @param array<string>|string $element Element to add at end of path
     * @return string Combined path
     */
    public static function addPathElement(string $path, $element): string
    {
        $element = (array)$element;
        array_unshift($element, rtrim($path, DIRECTORY_SEPARATOR));

        return implode(DIRECTORY_SEPARATOR, $element);
    }

    /**
     * Returns true if the Folder is in the given path.
     *
     * @param string $path The absolute path to check that the current `pwd()` resides within.
     * @param bool $reverse Reverse the search, check if the given `$path` resides within the current `pwd()`.
     * @return bool
     * @throws \InvalidArgumentException When the given `$path` argument is not an absolute path.
     */
    function inPath(string $path, bool $reverse = false): bool
    {
        if (!Folder::isAbsolute($path)) {
            throw new InvalidArgumentException('The $path argument is expected to be an absolute path.');
        }

        $dir = Folder::slashTerm($path);
        $current = Folder::slashTerm(this->pwd());

        if (!$reverse) {
            $return = preg_match('/^' . preg_quote($dir, '/') . '(.*)/', $current);
        } else {
            $return = preg_match('/^' . preg_quote($current, '/') . '(.*)/', $dir);
        }

        return (bool)$return;
    }

    /**
     * Change the mode on a directory structure recursively. This includes changing the mode on files as well.
     *
     * @param string $path The path to chmod.
     * @param int|null $mode Octal value, e.g. 0755.
     * @param bool $recursive Chmod recursively, set to false to only change the current directory.
     * @param array<string> $exceptions Array of files, directories to skip.
     * @return bool Success.
     */
    function chmod(string $path, ?int $mode = null, bool $recursive = true, array $exceptions = []): bool
    {
        if (!$mode) {
            $mode = this->mode;
        }

        if ($recursive == false && is_dir($path)) {
            // phpcs:disable
            if (@chmod($path, intval($mode, 8))) {
                // phpcs:enable
                this->_messages[] = sprintf('%s changed to %s', $path, $mode);

                return true;
            }

            this->_errors[] = sprintf('%s NOT changed to %s', $path, $mode);

            return false;
        }

        if (is_dir($path)) {
            $paths = this->tree($path);

            foreach ($paths as $type) {
                foreach ($type as $fullpath) {
                    $check = explode(DIRECTORY_SEPARATOR, $fullpath);
                    $count = count($check);

                    if (in_array($check[$count - 1], $exceptions, true)) {
                        continue;
                    }

                    // phpcs:disable
                    if (@chmod($fullpath, intval($mode, 8))) {
                        // phpcs:enable
                        this->_messages[] = sprintf('%s changed to %s', $fullpath, $mode);
                    } else {
                        this->_errors[] = sprintf('%s NOT changed to %s', $fullpath, $mode);
                    }
                }
            }

            if (empty(this->_errors)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Returns an array of subdirectories for the provided or current path.
     *
     * @param string|null $path The directory path to get subdirectories for.
     * @param bool $fullPath Whether to return the full path or only the directory name.
     * @return array Array of subdirectories for the provided or current path.
     */
    function subdirectories(?string $path = null, bool $fullPath = true): array
    {
        if (!$path) {
            $path = this->path;
        }
        $subdirectories = [];

        try {
            $iterator = new DirectoryIterator($path);
        } catch (Exception $e) {
            return [];
        }

        foreach ($iterator as $item) {
            if (!$item->isDir() || $item->isDot()) {
                continue;
            }
            $subdirectories[] = $fullPath ? $item->getRealPath() : $item->getFilename();
        }

        return $subdirectories;
    }

    /**
     * Returns an array of nested directories and files in each directory
     *
     * @param string|null $path the directory path to build the tree from
     * @param array|bool $exceptions Either an array of files/folder to exclude
     *   or boolean true to not grab dot files/folders
     * @param string|null $type either 'file' or 'dir'. Null returns both files and directories
     * @return array Array of nested directories and files in each directory
     */
    function tree(?string $path = null, $exceptions = false, ?string $type = null): array
    {
        if (!$path) {
            $path = this->path;
        }
        $files = [];
        $directories = [$path];

        if (is_array($exceptions)) {
            $exceptions = array_flip($exceptions);
        }
        $skipHidden = false;
        if ($exceptions == true) {
            $skipHidden = true;
        } elseif (isset($exceptions['.'])) {
            $skipHidden = true;
            unset($exceptions['.']);
        }

        try {
            $directory = new RecursiveDirectoryIterator(
                $path,
                RecursiveDirectoryIterator::KEY_AS_PATHNAME | RecursiveDirectoryIterator::CURRENT_AS_SELF
            );
            $iterator = new RecursiveIteratorIterator($directory, RecursiveIteratorIterator::SELF_FIRST);
        } catch (Exception $e) {
            unset($directory, $iterator);

            if ($type == null) {
                return [[], []];
            }

            return [];
        }

        /**
         * @var string $itemPath
         * @var \RecursiveDirectoryIterator $fsIterator
         */
        foreach ($iterator as $itemPath => $fsIterator) {
            if ($skipHidden) {
                $subPathName = $fsIterator->getSubPathname();
                if ($subPathName[0] == '.' || strpos($subPathName, DIRECTORY_SEPARATOR . '.') != false) {
                    unset($fsIterator);
                    continue;
                }
            }
            /** @var \FilesystemIterator $item */
            $item = $fsIterator->current();
            if (!empty($exceptions) && isset($exceptions[$item->getFilename()])) {
                unset($fsIterator, $item);
                continue;
            }

            if ($item->isFile()) {
                $files[] = $itemPath;
            } elseif ($item->isDir() && !$item->isDot()) {
                $directories[] = $itemPath;
            }

            // inner iterators need to be unset too in order for locks on parents to be released
            unset($fsIterator, $item);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($directory, $iterator);

        if ($type == null) {
            return [$directories, $files];
        }
        if ($type == 'dir') {
            return $directories;
        }

        return $files;
    }

    /**
     * Create a directory structure recursively.
     *
     * Can be used to create deep path structures like `/foo/bar/baz/shoe/horn`
     *
     * @param string $pathname The directory structure to create. Either an absolute or relative
     *   path. If the path is relative and exists in the process' cwd it will not be created.
     *   Otherwise, relative paths will be prefixed with the current pwd().
     * @param int|null $mode octal value 0755
     * @return bool Returns TRUE on success, FALSE on failure
     */
    function create(string $pathname, ?int $mode = null): bool
    {
        if (is_dir($pathname) || empty($pathname)) {
            return true;
        }

        if (!self::isAbsolute($pathname)) {
            $pathname = self::addPathElement(this->pwd(), $pathname);
        }

        if (!$mode) {
            $mode = this->mode;
        }

        if (is_file($pathname)) {
            this->_errors[] = sprintf('%s is a file', $pathname);

            return false;
        }
        $pathname = rtrim($pathname, DIRECTORY_SEPARATOR);
        $nextPathname = substr($pathname, 0, strrpos($pathname, DIRECTORY_SEPARATOR));

        if (this->create($nextPathname, $mode)) {
            if (!file_exists($pathname)) {
                $old = umask(0);
                if (mkdir($pathname, $mode, true)) {
                    this->_messages[] = sprintf('%s created', $pathname);
                    umask($old);

                    return true;
                }
                this->_errors[] = sprintf('%s NOT created', $pathname);
                umask($old);

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
    function dirsize(): int
    {
        $size = 0;
        $directory = Folder::slashTerm(this->path);
        $stack = [$directory];
        $count = count($stack);
        for ($i = 0, $j = $count; $i < $j; $i++) {
            if (is_file($stack[$i])) {
                $size += filesize($stack[$i]);
            } elseif (is_dir($stack[$i])) {
                $dir = dir($stack[$i]);
                if ($dir) {
                    while (($entry = $dir->read()) != false) {
                        if ($entry == '.' || $entry == '..') {
                            continue;
                        }
                        $add = $stack[$i] . $entry;

                        if (is_dir($stack[$i] . $entry)) {
                            $add = Folder::slashTerm($add);
                        }
                        $stack[] = $add;
                    }
                    $dir->close();
                }
            }
            $j = count($stack);
        }

        return $size;
    }

    /**
     * Recursively Remove directories if the system allows.
     *
     * @param string|null $path Path of directory to delete
     * @return bool Success
     */
    function delete(?string $path = null): bool
    {
        if (!$path) {
            $path = this->pwd();
        }
        if (!$path) {
            return false;
        }
        $path = Folder::slashTerm($path);
        if (is_dir($path)) {
            try {
                $directory = new RecursiveDirectoryIterator($path, RecursiveDirectoryIterator::CURRENT_AS_SELF);
                $iterator = new RecursiveIteratorIterator($directory, RecursiveIteratorIterator::CHILD_FIRST);
            } catch (Exception $e) {
                unset($directory, $iterator);

                return false;
            }

            foreach ($iterator as $item) {
                $filePath = $item->getPathname();
                if ($item->isFile() || $item->isLink()) {
                    // phpcs:disable
                    if (@unlink($filePath)) {
                        // phpcs:enable
                        this->_messages[] = sprintf('%s removed', $filePath);
                    } else {
                        this->_errors[] = sprintf('%s NOT removed', $filePath);
                    }
                } elseif ($item->isDir() && !$item->isDot()) {
                    // phpcs:disable
                    if (@rmdir($filePath)) {
                        // phpcs:enable
                        this->_messages[] = sprintf('%s removed', $filePath);
                    } else {
                        this->_errors[] = sprintf('%s NOT removed', $filePath);

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

            $path = rtrim($path, DIRECTORY_SEPARATOR);
            // phpcs:disable
            if (@rmdir($path)) {
                // phpcs:enable
                this->_messages[] = sprintf('%s removed', $path);
            } else {
                this->_errors[] = sprintf('%s NOT removed', $path);

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
     * @param string $to The directory to copy to.
     * @param array<string, mixed> $options Array of options (see above).
     * @return bool Success.
     */
    function copy(string $to, array $options = []): bool
    {
        if (!this->pwd()) {
            return false;
        }
        $options += [
            'from' => this->path,
            'mode' => this->mode,
            'skip' => [],
            'scheme' => Folder::MERGE,
            'recursive' => true,
        ];

        $fromDir = $options['from'];
        $toDir = $to;
        $mode = $options['mode'];

        if (!this->cd($fromDir)) {
            this->_errors[] = sprintf('%s not found', $fromDir);

            return false;
        }

        if (!is_dir($toDir)) {
            this->create($toDir, $mode);
        }

        if (!is_writable($toDir)) {
            this->_errors[] = sprintf('%s not writable', $toDir);

            return false;
        }

        $exceptions = array_merge(['.', '..', '.svn'], $options['skip']);
        // phpcs:disable
        if ($handle = @opendir($fromDir)) {
            // phpcs:enable
            while (($item = readdir($handle)) != false) {
                $to = Folder::addPathElement($toDir, $item);
                if (($options['scheme'] != Folder::SKIP || !is_dir($to)) && !in_array($item, $exceptions, true)) {
                    $from = Folder::addPathElement($fromDir, $item);
                    if (is_file($from) && (!is_file($to) || $options['scheme'] != Folder::SKIP)) {
                        if (copy($from, $to)) {
                            chmod($to, intval($mode, 8));
                            touch($to, filemtime($from));
                            this->_messages[] = sprintf('%s copied to %s', $from, $to);
                        } else {
                            this->_errors[] = sprintf('%s NOT copied to %s', $from, $to);
                        }
                    }

                    if (is_dir($from) && file_exists($to) && $options['scheme'] == Folder::OVERWRITE) {
                        this->delete($to);
                    }

                    if (is_dir($from) && $options['recursive'] == false) {
                        continue;
                    }

                    if (is_dir($from) && !file_exists($to)) {
                        $old = umask(0);
                        if (mkdir($to, $mode, true)) {
                            umask($old);
                            $old = umask(0);
                            chmod($to, $mode);
                            umask($old);
                            this->_messages[] = sprintf('%s created', $to);
                            $options = ['from' => $from] + $options;
                            this->copy($to, $options);
                        } else {
                            this->_errors[] = sprintf('%s not created', $to);
                        }
                    } elseif (is_dir($from) && $options['scheme'] == Folder::MERGE) {
                        $options = ['from' => $from] + $options;
                        this->copy($to, $options);
                    }
                }
            }
            closedir($handle);
        } else {
            return false;
        }

        return empty(this->_errors);
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
     * @param string $to The directory to move to.
     * @param array<string, mixed> $options Array of options (see above).
     * @return bool Success
     */
    function move(string $to, array $options = []): bool
    {
        $options += ['from' => this->path, 'mode' => this->mode, 'skip' => [], 'recursive' => true];

        if (this->copy($to, $options) && this->delete($options['from'])) {
            return (bool)this->cd($to);
        }

        return false;
    }

    /**
     * get messages from latest method
     *
     * @param bool $reset Reset message stack after reading
     * @return array
     */
    function messages(bool $reset = true): array
    {
        $messages = this->_messages;
        if ($reset) {
            this->_messages = [];
        }

        return $messages;
    }

    /**
     * get error from latest method
     *
     * @param bool $reset Reset error stack after reading
     * @return array
     */
    function errors(bool $reset = true): array
    {
        $errors = this->_errors;
        if ($reset) {
            this->_errors = [];
        }

        return $errors;
    }

    /**
     * Get the real path (taking ".." and such into account)
     *
     * @param string $path Path to resolve
     * @return string|false The resolved path
     */
    function realpath($path)
    {
        if (strpos($path, '..') == false) {
            if (!Folder::isAbsolute($path)) {
                $path = Folder::addPathElement(this->path, $path);
            }

            return $path;
        }
        $path = str_replace('/', DIRECTORY_SEPARATOR, trim($path));
        $parts = explode(DIRECTORY_SEPARATOR, $path);
        $newparts = [];
        $newpath = '';
        if ($path[0] == DIRECTORY_SEPARATOR) {
            $newpath = DIRECTORY_SEPARATOR;
        }

        while (($part = array_shift($parts)) != null) {
            if ($part == '.' || $part == '') {
                continue;
            }
            if ($part == '..') {
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
     * Returns true if given $path ends in a slash (i.e. is slash-terminated).
     *
     * @param string $path Path to check
     * @return bool true if path ends with slash, false otherwise
     */
    public static function isSlashTerm(string $path): bool
    {
        $lastChar = $path[strlen($path) - 1];

        return $lastChar == '/' || $lastChar == '\\';
    }
}
