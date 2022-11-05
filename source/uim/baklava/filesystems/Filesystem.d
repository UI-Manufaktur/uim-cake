module uim.baklava.Filesystem;

import uim.baklava.core.exceptions\CakeException;
use CallbackFilterIterator;
use FilesystemIterator;
use Iterator;
use RecursiveCallbackFilterIterator;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use RegexIterator;
use SplFileInfo;

/**
 * This provides convenience wrappers around common filesystem queries.
 *
 * This is an internal helper class that should not be used in application code
 * as it provides no guarantee for compatibility.
 *
 * @internal
 */
class Filesystem
{
    /**
     * Directory type constant
     *
     * @var string
     */
    public const TYPE_DIR = 'dir';

    /**
     * Find files / directories (non-recursively) in given directory path.
     *
     * @param string myPath Directory path.
     * @param mixed $filter If string will be used as regex for filtering using
     *   `RegexIterator`, if callable will be as callback for `CallbackFilterIterator`.
     * @param int|null $flags Flags for FilesystemIterator::this();
     * @return \Iterator
     */
    function find(string myPath, $filter = null, Nullable!int $flags = null): Iterator
    {
        $flags = $flags ?? FilesystemIterator::KEY_AS_PATHNAME
            | FilesystemIterator::CURRENT_AS_FILEINFO
            | FilesystemIterator::SKIP_DOTS;
        $directory = new FilesystemIterator(myPath, $flags);

        if ($filter === null) {
            return $directory;
        }

        return this.filterIterator($directory, $filter);
    }

    /**
     * Find files/ directories recursively in given directory path.
     *
     * @param string myPath Directory path.
     * @param mixed $filter If string will be used as regex for filtering using
     *   `RegexIterator`, if callable will be as callback for `CallbackFilterIterator`.
     *   Hidden directories (starting with dot e.g. .git) are always skipped.
     * @param int|null $flags Flags for FilesystemIterator::this();
     * @return \Iterator
     */
    function findRecursive(string myPath, $filter = null, Nullable!int $flags = null): Iterator
    {
        $flags = $flags ?? FilesystemIterator::KEY_AS_PATHNAME
            | FilesystemIterator::CURRENT_AS_FILEINFO
            | FilesystemIterator::SKIP_DOTS;
        $directory = new RecursiveDirectoryIterator(myPath, $flags);

        $dirFilter = new RecursiveCallbackFilterIterator(
            $directory,
            function (SplFileInfo $current) {
                if ($current.getFilename()[0] === '.' && $current.isDir()) {
                    return false;
                }

                return true;
            }
        );

        $flatten = new RecursiveIteratorIterator(
            $dirFilter,
            RecursiveIteratorIterator::CHILD_FIRST
        );

        if ($filter === null) {
            return $flatten;
        }

        return this.filterIterator($flatten, $filter);
    }

    /**
     * Wrap iterator in additional filtering iterator.
     *
     * @param \Iterator $iterator Iterator
     * @param mixed $filter Regex string or callback.
     * @return \Iterator
     */
    protected auto filterIterator(Iterator $iterator, $filter): Iterator
    {
        if (is_string($filter)) {
            return new RegexIterator($iterator, $filter);
        }

        return new CallbackFilterIterator($iterator, $filter);
    }

    /**
     * Dump contents to file.
     *
     * @param string myfilename File path.
     * @param string myContents Content to dump.
     * @return void
     * @throws \Cake\Core\Exception\CakeException When dumping fails.
     */
    function dumpFile(string myfilename, string myContents): void
    {
        $dir = dirname(myfilename);
        if (!is_dir($dir)) {
            this.mkdir($dir);
        }

        $exists = file_exists(myfilename);

        if (this.isStream(myfilename)) {
            // phpcs:ignore
            $success = @file_put_contents(myfilename, myContents);
        } else {
            // phpcs:ignore
            $success = @file_put_contents(myfilename, myContents, LOCK_EX);
        }

        if ($success === false) {
            throw new CakeException(sprintf('Failed dumping content to file `%s`', $dir));
        }

        if (!$exists) {
            chmod(myfilename, 0666 & ~umask());
        }
    }

    /**
     * Create directory.
     *
     * @param string $dir Directory path.
     * @param int myMode Octal mode passed to mkdir(). Defaults to 0755.
     * @return void
     * @throws \Cake\Core\Exception\CakeException When directory creation fails.
     */
    function mkdir(string $dir, int myMode = 0755): void
    {
        if (is_dir($dir)) {
            return;
        }

        $old = umask(0);
        // phpcs:ignore
        if (@mkdir($dir, myMode, true) === false) {
            umask($old);
            throw new CakeException(sprintf('Failed to create directory "%s"', $dir));
        }

        umask($old);
    }

    /**
     * Delete directory along with all it's contents.
     *
     * @param string myPath Directory path.
     * @return bool
     * @throws \Cake\Core\Exception\CakeException If path is not a directory.
     */
    bool deleteDir(string myPath)
    {
        if (!file_exists(myPath)) {
            return true;
        }

        if (!is_dir(myPath)) {
            throw new CakeException(sprintf('"%s" is not a directory', myPath));
        }

        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator(myPath, FilesystemIterator::SKIP_DOTS),
            RecursiveIteratorIterator::CHILD_FIRST
        );

        myResult = true;
        foreach ($iterator as myfileInfo) {
            $isWindowsLink = DIRECTORY_SEPARATOR === '\\' && myfileInfo.getType() === 'link';
            if (myfileInfo.getType() === self::TYPE_DIR || $isWindowsLink) {
                // phpcs:ignore
                myResult = myResult && @rmdir(myfileInfo.getPathname());
                unset(myfileInfo);
                continue;
            }

            // phpcs:ignore
            myResult = myResult && @unlink(myfileInfo.getPathname());
            // possible inner iterators need to be unset too in order for locks on parents to be released
            unset(myfileInfo);
        }

        // unsetting iterators helps releasing possible locks in certain environments,
        // which could otherwise make `rmdir()` fail
        unset($iterator);

        // phpcs:ignore
        myResult = myResult && @rmdir(myPath);

        return myResult;
    }

    /**
     * Copies directory with all it's contents.
     *
     * @param string $source Source path.
     * @param string $destination Destination path.
     * @return bool
     */
    bool copyDir(string $source, string $destination)
    {
        $destination = (new SplFileInfo($destination)).getPathname();

        if (!is_dir($destination)) {
            this.mkdir($destination);
        }

        $iterator = new FilesystemIterator($source);

        myResult = true;
        foreach ($iterator as myfileInfo) {
            if (myfileInfo.isDir()) {
                myResult = myResult && this.copyDir(
                    myfileInfo.getPathname(),
                    $destination . DIRECTORY_SEPARATOR . myfileInfo.getFilename()
                );
            } else {
                // phpcs:ignore
                myResult = myResult && @copy(
                    myfileInfo.getPathname(),
                    $destination . DIRECTORY_SEPARATOR . myfileInfo.getFilename()
                );
            }
        }

        return myResult;
    }

    /**
     * Check whether the given path is a stream path.
     *
     * @param string myPath Path.
     * @return bool
     */
    bool isStream(string myPath)
    {
        return strpos(myPath, '://') !== false;
    }
}
