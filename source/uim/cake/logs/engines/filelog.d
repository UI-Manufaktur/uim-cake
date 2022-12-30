/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/module uim.cake.logs.engines;

@safe:
import uim.cake;

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
    protected string _path;

    /**
     * The name of the file to save logs into.
     *
     * @var string|null
     */
    protected _file;

    /**
     * Max file size, used for log file rotation.
     *
     * @var int|null
     */
    protected _size;

    /**
     * Sets protected properties based on config provided
     *
     * @param array<string, mixed> myConfig Configuration array
     */
    this(array myConfig = []) {
        super.this(myConfig);

        _path = this.getConfig("path", sys_get_temp_dir() . DIRECTORY_SEPARATOR);
        if (Configure::read("debug") && !is_dir(_path)) {
            mkdir(_path, 0775, true);
        }

        if (!empty(_config["file"])) {
            _file = _config["file"];
            if (substr(_file, -4) != ".log") {
                _file .= ".log";
            }
        }

        if (!empty(_config["size"])) {
            if (is_numeric(_config["size"])) {
                _size = (int)_config["size"];
            } else {
                _size = Text::parseFileSize(_config["size"]);
            }
        }

        if (isset(_config["dateFormat"])) {
            deprecationWarning("`dateFormat` option should now be set in the formatter options.", 0);
            this.formatter.setConfig("dateFormat", _config["dateFormat"]);
        }
    }

    /**
     * : writing to log files.
     *
     * @param mixed $level The severity level of the message being written.
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void
     * @see uim.cake.logs.Log::$_levels
     */
    void log($level, myMessage, array $context = []) {
        myMessage = _format(myMessage, $context);
        myMessage = this.formatter.format($level, myMessage, $context);

        myfilename = _getFilename($level);
        if (_size) {
            _rotateFile(myfilename);
        }

        myPathname = _path . myfilename;
        $mask = _config["mask"];
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
     * @param string level The level of log.
     * @return string File name
     */
    protected string _getFilename(string level) {
        $debugTypes = ["notice", "info", "debug"];

        if (_file) {
            myfilename = _file;
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
        myfilePath = _path . myfilename;
        clearstatcache(true, myfilePath);

        if (
            !is_file(myfilePath) ||
            filesize(myfilePath) < _size
        ) {
            return null;
        }

        $rotate = _config["rotate"];
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
