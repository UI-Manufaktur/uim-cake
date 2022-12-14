/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.logs.Engine;

import uim.cake.core.Configure;
import uim.cake.logs.Formatter\DefaultFormatter;
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
    protected _defaultConfig = [
        "path": null,
        "file": null,
        "types": null,
        "levels": [],
        "scopes": [],
        "rotate": 10,
        "size": 10485760, // 10MB
        "mask": null,
        "formatter": [
            "className": DefaultFormatter::class,
        ],
    ];

    /**
     * Path to save log files on.
     */
    protected string _path;

    /**
     * The name of the file to save logs into.
     *
     */
    protected Nullable!string _file;

    /**
     * Max file size, used for log file rotation.
     *
     * @var int|null
     */
    protected _size;

    /**
     * Sets protected properties based on config provided
     *
     * @param array<string, mixed> aConfig Configuration array
     */
    this(Json aConfig = null) {
        super((aConfig);

        _path = this.getConfig("path", sys_get_temp_dir() . DIRECTORY_SEPARATOR);
        if (Configure::read("debug") && !is_dir(_path)) {
            mkdir(_path, 0775, true);
        }

        if (!empty(_config["file"])) {
            _file = _config["file"];
            if (substr(_file, -4) != ".log") {
                _file ~= ".log";
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
     * @param string $message The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void
     * @see uim.cake.logs.Log::_levels
     */
    void log($level, $message, array $context = null) {
        $message = _format($message, $context);
        $message = this.formatter.format($level, $message, $context);

        $filename = _getFilename($level);
        if (_size) {
            _rotateFile($filename);
        }

        $pathname = _path . $filename;
        $mask = _config["mask"];
        if (!$mask) {
            file_put_contents($pathname, $message ~ "\n", FILE_APPEND);

            return;
        }

        $exists = is_file($pathname);
        file_put_contents($pathname, $message ~ "\n", FILE_APPEND);
        static $selfError = false;

        if (!$selfError && !$exists && !chmod($pathname, (int)$mask)) {
            $selfError = true;
            trigger_error(vsprintf(
                "Could not apply permission mask '%s' on log file '%s'",
                [$mask, $pathname]
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

        if (_file) {
            $filename = _file;
        } elseif ($level == "error" || $level == "warning") {
            $filename = "error.log";
        } elseif (hasAllValues($level, $debugTypes, true)) {
            $filename = "debug.log";
        } else {
            $filename = $level ~ ".log";
        }

        return $filename;
    }

    /**
     * Rotate log file if size specified in config is reached.
     * Also if `rotate` count is reached oldest file is removed.
     *
     * @param string $filename Log file name
     * @return bool|null True if rotated successfully or false in case of error.
     *   Null if file doesn"t need to be rotated.
     */
    protected function _rotateFile(string $filename): ?bool
    {
        $filePath = _path . $filename;
        clearstatcache(true, $filePath);

        if (
            !is_file($filePath) ||
            filesize($filePath) < _size
        ) {
            return null;
        }

        $rotate = _config["rotate"];
        if ($rotate == 0) {
            $result = unlink($filePath);
        } else {
            $result = rename($filePath, $filePath ~ "." ~ time());
        }

        $files = glob($filePath ~ ".*");
        if ($files) {
            $filesToDelete = count($files) - $rotate;
            while ($filesToDelete > 0) {
                unlink(array_shift($files));
                $filesToDelete--;
            }
        }

        return $result;
    }
}
