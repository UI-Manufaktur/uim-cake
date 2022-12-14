

/**
 * UIM(tm) :  Rapid Development Framework (https://UIM.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org UIM(tm) Project
 * @since         1.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs.engines;

import uim.cake.core.Configure;
import uim.cake.logs.formatters\DefaultFormatter;
import uim.cake.utilities.Text;

/**
 * File Storage stream for Logging. Writes logs to different files
 * based on the level of log it is.
 */
class FileLog : BaseLog
{
    /**
     * Default config for this class
     *
     * - `levels` string or array, levels the engine is interested in
     * - `scopes` string or array, scopes the engine is interested in
     * - `file` Log file name
     * - `path` The path to save logs on.
     * - `size` Used to implement basic log file rotation. If log file size
     *   reaches specified size the existing file is renamed by appending timestamp
     *   to filename and new log file is created. Can be integer bytes value or
     *   human readable string values like "10MB", "100KB" etc.
     * - `rotate` Log files are rotated specified times before being removed.
     *   If value is 0, old versions are removed rather then rotated.
     * - `mask` A mask is applied when log files are created. Left empty no chmod
     *   is made.
     * - `dateFormat` PHP date() format.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "path":null,
        "file":null,
        "types":null,
        "levels":[],
        "scopes":[],
        "rotate":10,
        "size":10485760, // 10MB
        "mask":null,
        "formatter":[
            "className":DefaultFormatter::class,
        ],
    ];

    /**
     * Path to save log files on.
     */
    protected string $_path;

    /**
     * The name of the file to save logs into.
     *
     * @var string|null
     */
    protected $_file;

    /**
     * Max file size, used for log file rotation.
     *
     * @var int|null
     */
    protected $_size;

    /**
     * Sets protected properties based on config provided
     *
     * @param array<string, mixed> myConfig Configuration array
     */
    this(array myConfig = []) {
        super.this(myConfig);

        this._path = this.getConfig("path", sys_get_temp_dir() . DIRECTORY_SEPARATOR);
        if (Configure::read("debug") && !is_dir(this._path)) {
            mkdir(this._path, 0775, true);
        }

        if (!empty(this._config["file"])) {
            this._file = this._config["file"];
            if (substr(this._file, -4) !== ".log") {
                this._file .= ".log";
            }
        }

        if (!empty(this._config["size"])) {
            if (is_numeric(this._config["size"])) {
                this._size = (int)this._config["size"];
            } else {
                this._size = Text::parseFileSize(this._config["size"]);
            }
        }

        if (isset(this._config["dateFormat"])) {
            deprecationWarning("`dateFormat` option should now be set in the formatter options.", 0);
            this.formatter.setConfig("dateFormat", this._config["dateFormat"]);
        }
    }

    /**
     * : writing to log files.
     *
     * @param mixed $level The severity level of the message being written.
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void
     * @see \Cake\Log\Log::$_levels
     */
    void log($level, myMessage, array $context = [])
    {
        myMessage = this._format(myMessage, $context);
        myMessage = this.formatter.format($level, myMessage, $context);

        myfilename = this._getFilename($level);
        if (this._size) {
            this._rotateFile(myfilename);
        }

        myPathname = this._path . myfilename;
        $mask = this._config["mask"];
        if (!$mask) {
            file_put_contents(myPathname, myMessage . "\n", FILE_APPEND);

            return;
        }

        $exists = is_file(myPathname);
        file_put_contents(myPathname, myMessage . "\n", FILE_APPEND);
        static $selfError = false;

        if (!$selfError && !$exists && !chmod(myPathname, (int)$mask)) {
            $selfError = true;
            trigger_error(vsprintf(
                "Could not apply permission mask "%s" on log file "%s"",
                [$mask, myPathname]
            ), E_USER_WARNING);
            $selfError = false;
        }
    }

    /**
     * Get filename
     *
     * @param string $level The level of log.
     * @return string File name
     */
    protected string _getFilename(string $level) {
        $debugTypes = ["notice", "info", "debug"];

        if (this._file) {
            myfilename = this._file;
        } elseif ($level == "error" || $level == "warning") {
            myfilename = "error.log";
        } elseif (in_array($level, $debugTypes, true)) {
            myfilename = "debug.log";
        } else {
            myfilename = $level . ".log";
        }

        return myfilename;
    }

    /**
     * Rotate log file if size specified in config is reached.
     * Also if `rotate` count is reached oldest file is removed.
     *
     * @param string myfilename Log file name
     * @return bool|null True if rotated successfully or false in case of error.
     *   Null if file doesn"t need to be rotated.
     */
    protected auto _rotateFile(string myfilename): ?bool
    {
        myfilePath = this._path . myfilename;
        clearstatcache(true, myfilePath);

        if (
            !is_file(myfilePath) ||
            filesize(myfilePath) < this._size
        ) {
            return null;
        }

        $rotate = this._config["rotate"];
        if ($rotate == 0) {
            myResult = unlink(myfilePath);
        } else {
            myResult = rename(myfilePath, myfilePath . "." . time());
        }

        myfiles = glob(myfilePath . ".*");
        if (myfiles) {
            myfilesToDelete = count(myfiles) - $rotate;
            while (myfilesToDelete > 0) {
                unlink(array_shift(myfiles));
                myfilesToDelete--;
            }
        }

        return myResult;
    }
}
