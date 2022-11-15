module uim.cake.filesystems.file;

use finfo;
use SplFileInfo;

/**
 * Convenience class for reading, writing and appending to files.
 *
 * @deprecated 4.0.0 Will be removed in 5.0.
 */
class File {
    /**
     * Folder object of the file
     *
     * @var \Cake\Filesystem\Folder
     * @link https://book.cakephp.org/4/en/core-libraries/file-folder.html
     */
    public $Folder;

    /**
     * File name
     *
     * @var string
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\File::myName
     */
    public myName;

    /**
     * File info
     *
     * @var array<string, mixed>
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\File::$info
     */
    public $info = [];

    /**
     * Holds the file handler resource if the file is opened
     *
     * @var resource|null
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\File::$handle
     */
    public $handle;

    /**
     * Enable locking for file reading and writing
     *
     * @var bool|null
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\File::$lock
     */
    public $lock;

    /**
     * Path property
     *
     * Current file"s absolute path
     *
     * @var string|null
     * https://book.cakephp.org/4/en/core-libraries/file-folder.html#Cake\Filesystem\File::myPath
     */
    public myPath;

    /**
     * Constructor
     *
     * @param string myPath Path to file
     * @param bool $create Create file if it does not exist (if true)
     * @param int myMode Mode to apply to the folder holding the file
     * @link https://book.cakephp.org/4/en/core-libraries/file-folder.html#file-api
     */
    this(string myPath, bool $create = false, int myMode = 0755) {
        $splInfo = new SplFileInfo(myPath);
        this.Folder = new Folder($splInfo.getPath(), $create, myMode);
        if (!is_dir(myPath)) {
            this.name = ltrim($splInfo.getFilename(), "/\\");
        }
        this.pwd();
        $create && !this.exists() && this.safe(myPath) && this.create();
    }

    /**
     * Closes the current file if it is opened
     */
    auto __destruct() {
        this.close();
    }

    /**
     * Creates the file.
     *
     * @return bool Success
     */
    bool create() {
        $dir = this.Folder.pwd();

        if (is_dir($dir) && is_writable($dir) && !this.exists() && touch(this.path)) {
            return true;
        }

        return false;
    }

    /**
     * Opens the current file with a given myMode
     *
     * @param string myMode A valid "fopen" mode string (r|w|a ...)
     * @param bool $force If true then the file will be re-opened even if its already opened, otherwise it won"t
     * @return bool True on success, false on failure
     */
    bool open(string myMode = "r", bool $force = false) {
        if (!$force && is_resource(this.handle)) {
            return true;
        }
        if (this.exists() === false && this.create() === false) {
            return false;
        }

        this.handle = fopen(this.path, myMode);

        return is_resource(this.handle);
    }

    /**
     * Return the contents of this file as a string.
     *
     * @param string|false $bytes where to start
     * @param string myMode A `fread` compatible mode.
     * @param bool $force If true then the file will be re-opened even if its already opened, otherwise it won"t
     * @return string|false String on success, false on failure
     */
    function read($bytes = false, string myMode = "rb", bool $force = false) {
        if ($bytes === false && this.lock === null) {
            return file_get_contents(this.path);
        }
        if (this.open(myMode, $force) === false) {
            return false;
        }
        if (this.lock !== null && flock(this.handle, LOCK_SH) === false) {
            return false;
        }
        if (is_int($bytes)) {
            return fread(this.handle, $bytes);
        }

        myData = "";
        while (!feof(this.handle)) {
            myData .= fgets(this.handle, 4096);
        }

        if (this.lock !== null) {
            flock(this.handle, LOCK_UN);
        }
        if ($bytes === false) {
            this.close();
        }

        return trim(myData);
    }

    /**
     * Sets or gets the offset for the currently opened file.
     *
     * @param int|false $offset The $offset in bytes to seek. If set to false then the current offset is returned.
     * @param int $seek PHP Constant SEEK_SET | SEEK_CUR | SEEK_END determining what the $offset is relative to
     * @return int|bool True on success, false on failure (set mode), false on failure
     *   or integer offset on success (get mode).
     */
    function offset($offset = false, int $seek = SEEK_SET) {
        if ($offset === false) {
            if (is_resource(this.handle)) {
                return ftell(this.handle);
            }
        } elseif (this.open() === true) {
            return fseek(this.handle, $offset, $seek) === 0;
        }

        return false;
    }

    /**
     * Prepares an ASCII string for writing. Converts line endings to the
     * correct terminator for the current platform. If Windows, "\r\n" will be used,
     * all other platforms will use "\n"
     *
     * @param string myData Data to prepare for writing.
     * @param bool $forceWindows If true forces Windows new line string.
     * @return string The with converted line endings.
     */
    static string prepare(string myData, bool $forceWindows = false) {
        $lineBreak = "\n";
        if (DIRECTORY_SEPARATOR === "\\" || $forceWindows === true) {
            $lineBreak = "\r\n";
        }

        return strtr(myData, ["\r\n" => $lineBreak, "\n" => $lineBreak, "\r" => $lineBreak]);
    }

    /**
     * Write given data to this file.
     *
     * @param string myData Data to write to this File.
     * @param string myMode Mode of writing. {@link https://secure.php.net/fwrite See fwrite()}.
     * @param bool $force Force the file to open
     * @return bool Success
     */
    bool write(string myData, string myMode = "w", bool $force = false) {
        $success = false;
        if (this.open(myMode, $force) === true) {
            if (this.lock !== null && flock(this.handle, LOCK_EX) === false) {
                return false;
            }

            if (fwrite(this.handle, myData) !== false) {
                $success = true;
            }
            if (this.lock !== null) {
                flock(this.handle, LOCK_UN);
            }
        }

        return $success;
    }

    /**
     * Append given data string to this file.
     *
     * @param string myData Data to write
     * @param bool $force Force the file to open
     * @return bool Success
     */
    bool append(string myData, bool $force = false) {
        return this.write(myData, "a", $force);
    }

    /**
     * Closes the current file if it is opened.
     *
     * @return bool True if closing was successful or file was already closed, otherwise false
     */
    bool close() {
        if (!is_resource(this.handle)) {
            return true;
        }

        return fclose(this.handle);
    }

    /**
     * Deletes the file.
     *
     * @return bool Success
     */
    bool delete() {
        this.close();
        this.handle = null;
        if (this.exists()) {
            return unlink(this.path);
        }

        return false;
    }

    /**
     * Returns the file info as an array with the following keys:
     *
     * - dirname
     * - basename
     * - extension
     * - filename
     * - filesize
     * - mime
     *
     * @return array<string, mixed> File information.
     */
    function info(): array
    {
        if (!this.info) {
            this.info = pathinfo(this.path);
        }

        this.info["filename"] = this.info["filename"] ?? this.name();
        this.info["filesize"] = this.info["filesize"] ?? this.size();
        this.info["mime"] = this.info["mime"] ?? this.mime();

        return this.info;
    }

    /**
     * Returns the file extension.
     *
     * @return string|false The file extension, false if extension cannot be extracted.
     */
    function ext() {
        if (!this.info) {
            this.info();
        }

        return this.info["extension"] ?? false;
    }

    /**
     * Returns the file name without extension.
     *
     * @return string|false The file name without extension, false if name cannot be extracted.
     */
    function name() {
        if (!this.info) {
            this.info();
        }
        if (isset(this.info["extension"])) {
            return static::_basename(this.name, "." . this.info["extension"]);
        }
        if (this.name) {
            return this.name;
        }

        return false;
    }

    /**
     * Returns the file basename. simulate the php basename() for multibyte (mb_basename).
     *
     * @param string myPath Path to file
     * @param string|null $ext The name of the extension
     * @return string the file basename.
     */
    protected static string _basename(string myPath, Nullable!string $ext = null) {
        // check for multibyte string and use basename() if not found
        if (mb_strlen(myPath) === strlen(myPath)) {
            return $ext === null ? basename(myPath) : basename(myPath, $ext);
        }

        $splInfo = new SplFileInfo(myPath);
        myName = ltrim($splInfo.getFilename(), "/\\");

        if ($ext === null || $ext == "") {
            return myName;
        }
        $ext = preg_quote($ext);
        $new = preg_replace("/({$ext})$/u", "", myName);

        // basename of "/etc/.d" is ".d" not ""
        return $new == "" ? myName : $new;
    }

    /**
     * Makes file name safe for saving
     *
     * @param string|null myName The name of the file to make safe if different from this.name
     * @param string|null $ext The name of the extension to make safe if different from this.ext
     * @return string The extension of the file
     */
    string safe(Nullable!string myName = null, Nullable!string $ext = null) {
        if (!myName) {
            myName = (string)this.name;
        }
        if (!$ext) {
            $ext = (string)this.ext();
        }

        return preg_replace("/(?:[^\w\.-]+)/", "_", static::_basename(myName, $ext));
    }

    /**
     * Get md5 Checksum of file with previous check of Filesize
     *
     * @param int|true $maxsize in MB or true to force
     * @return string|false md5 Checksum {@link https://secure.php.net/md5_file See md5_file()},
     *  or false in case of an error.
     */
    function md5($maxsize = 5) {
        if ($maxsize === true) {
            return md5_file(this.path);
        }

        $size = this.size();
        if ($size && $size < $maxsize * 1024 * 1024) {
            return md5_file(this.path);
        }

        return false;
    }

    /**
     * Returns the full path of the file.
     *
     * @return string|null Full path to the file, or null on failure
     */
    function pwd() {
        if (this.path === null) {
            $dir = this.Folder.pwd();
            if ($dir && is_dir($dir)) {
                this.path = this.Folder.slashTerm($dir) . this.name;
            }
        }

        return this.path;
    }

    /**
     * Returns true if the file exists.
     *
     * @return bool True if it exists, false otherwise
     */
    bool exists() {
        this.clearStatCache();

        return this.path && file_exists(this.path) && is_file(this.path);
    }

    /**
     * Returns the "chmod" (permissions) of the file.
     *
     * @return string|false Permissions for the file, or false in case of an error
     */
    function perms() {
        if (this.exists()) {
            return decoct(fileperms(this.path) & 0777);
        }

        return false;
    }

    /**
     * Returns the file size
     *
     * @return int|false Size of the file in bytes, or false in case of an error
     */
    function size() {
        if (this.exists()) {
            return filesize(this.path);
        }

        return false;
    }

    /**
     * Returns true if the file is writable.
     *
     * @return bool True if it"s writable, false otherwise
     */
    bool writable() {
        return is_writable(this.path);
    }

    /**
     * Returns true if the File is executable.
     *
     * @return bool True if it"s executable, false otherwise
     */
    bool executable() {
        return is_executable(this.path);
    }

    /**
     * Returns true if the file is readable.
     *
     * @return bool True if file is readable, false otherwise
     */
    bool readable() {
        return is_readable(this.path);
    }

    /**
     * Returns the file"s owner.
     *
     * @return int|false The file owner, or bool in case of an error
     */
    function owner() {
        if (this.exists()) {
            return fileowner(this.path);
        }

        return false;
    }

    /**
     * Returns the file"s group.
     *
     * @return int|false The file group, or false in case of an error
     */
    function group() {
        if (this.exists()) {
            return filegroup(this.path);
        }

        return false;
    }

    /**
     * Returns last access time.
     *
     * @return int|false Timestamp of last access time, or false in case of an error
     */
    function lastAccess() {
        if (this.exists()) {
            return fileatime(this.path);
        }

        return false;
    }

    /**
     * Returns last modified time.
     *
     * @return int|false Timestamp of last modification, or false in case of an error
     */
    function lastChange() {
        if (this.exists()) {
            return filemtime(this.path);
        }

        return false;
    }

    /**
     * Returns the current folder.
     *
     * @return \Cake\Filesystem\Folder Current folder
     */
    function folder(): Folder
    {
        return this.Folder;
    }

    /**
     * Copy the File to $dest
     *
     * @param string $dest Absolute path to copy the file to.
     * @param bool $overwrite Overwrite $dest if exists
     * @return bool Success
     */
    bool copy(string $dest, bool $overwrite = true) {
        if (!this.exists() || is_file($dest) && !$overwrite) {
            return false;
        }

        return copy(this.path, $dest);
    }

    /**
     * Gets the mime type of the file. Uses the finfo extension if
     * it"s available, otherwise falls back to mime_content_type().
     *
     * @return string|false The mimetype of the file, or false if reading fails.
     */
    function mime() {
        if (!this.exists()) {
            return false;
        }
        if (class_exists("finfo")) {
            $finfo = new finfo(FILEINFO_MIME);
            myType = $finfo.file(this.pwd());
            if (!myType) {
                return false;
            }
            [myType] = explode(";", myType);

            return myType;
        }
        if (function_exists("mime_content_type")) {
            return mime_content_type(this.pwd());
        }

        return false;
    }

    /**
     * Clear PHP"s internal stat cache
     *
     * @param bool $all Clear all cache or not. Passing false will clear
     *   the stat cache for the current path only.
     * @return void
     */
    function clearStatCache($all = false): void
    {
        if ($all === false && this.path) {
            clearstatcache(true, this.path);
        }

        clearstatcache();
    }

    /**
     * Searches for a given text and replaces the text if found.
     *
     * @param array<string>|string $search Text(s) to search for.
     * @param array<string>|string $replace Text(s) to replace with.
     * @return bool Success
     */
    bool replaceText($search, $replace) {
        if (!this.open("r+")) {
            return false;
        }

        if (this.lock !== null && flock(this.handle, LOCK_EX) === false) {
            return false;
        }

        $replaced = this.write(str_replace($search, $replace, this.read()), "w", true);

        if (this.lock !== null) {
            flock(this.handle, LOCK_UN);
        }
        this.close();

        return $replaced;
    }
}