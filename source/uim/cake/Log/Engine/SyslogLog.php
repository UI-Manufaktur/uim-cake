

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         2.4.0
  */
module uim.cake.Log\Engine;

import uim.cake.Log\Formatter\DefaultFormatter;
import uim.cake.Log\Formatter\LegacySyslogFormatter;

/**
 * Syslog stream for Logging. Writes logs to the system logger
 */
class SyslogLog : BaseLog
{
    /**
     * Default config for this class
     *
     * By default messages are formatted as:
     * level: message
     *
     * To override the log format (e.g. to add your own info) define the format key when configuring
     * this logger
     *
     * If you wish to include a prefix to all messages, for instance to identify the
     * application or the web server, then use the prefix option. Please keep in mind
     * the prefix is shared by all streams using syslog, as it is dependent of
     * the running process. For a local prefix, to be used only by one stream, you
     * can use the format key.
     *
     * ### Example:
     *
     * ```
     *  Log::config("error", ]
     *      "engine": "Syslog",
     *      "levels": ["emergency", "alert", "critical", "error"],
     *      "prefix": "Web Server 01"
     *  ]);
     * ```
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "levels": [],
        "scopes": [],
        "flag": LOG_ODELAY,
        "prefix": "",
        "facility": LOG_USER,
        "formatter": [
            "className": DefaultFormatter::class,
            "includeDate": false,
        ],
    ];

    /**
     * Used to map the string names back to their LOG_* constants
     *
     * @var array<int>
     */
    protected $_levelMap = [
        "emergency": LOG_EMERG,
        "alert": LOG_ALERT,
        "critical": LOG_CRIT,
        "error": LOG_ERR,
        "warning": LOG_WARNING,
        "notice": LOG_NOTICE,
        "info": LOG_INFO,
        "debug": LOG_DEBUG,
    ];

    /**
     * Whether the logger connection is open or not
     *
     * @var bool
     */
    protected $_open = false;


    this(array $config = []) {
        if (isset($config["format"])) {
            deprecationWarning(
                "`format` option is now deprecated in favor of custom formatters. " .
                "Switching to `LegacySyslogFormatter`.",
                0
            );
            /** @psalm-suppress DeprecatedClass */
            $config["formatter"] = [
                "className": LegacySyslogFormatter::class,
                "format": $config["format"],
            ];
        }
        super(($config);
    }

    /**
     * Writes a message to syslog
     *
     * Map the $level back to a LOG_ constant value, split multi-line messages into multiple
     * log messages, pass all messages through the format defined in the configuration
     *
     * @param mixed $level The severity level of log you are making.
     * @param string $message The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void
     * @see uim.cake.Log\Log::$_levels
     */
    function log($level, $message, array $context = []): void
    {
        if (!_open) {
            $config = _config;
            _open($config["prefix"], $config["flag"], $config["facility"]);
            _open = true;
        }

        $priority = LOG_DEBUG;
        if (isset(_levelMap[$level])) {
            $priority = _levelMap[$level];
        }

        $lines = explode("\n", _format($message, $context));
        foreach ($lines as $line) {
            _write($priority, this.formatter.format($level, $line, $context));
        }
    }

    /**
     * Extracts the call to openlog() in order to run unit tests on it. This function
     * will initialize the connection to the system logger
     *
     * @param string $ident the prefix to add to all messages logged
     * @param int $options the options flags to be used for logged messages
     * @param int $facility the stream or facility to log to
     */
    protected void _open(string $ident, int $options, int $facility): void
    {
        openlog($ident, $options, $facility);
    }

    /**
     * Extracts the call to syslog() in order to run unit tests on it. This function
     * will perform the actual write in the system logger
     *
     * @param int $priority Message priority.
     * @param string $message Message to log.
     * @return bool
     */
    protected function _write(int $priority, string $message): bool
    {
        return syslog($priority, $message);
    }

    /**
     * Closes the logger connection
     */
    function __destruct() {
        closelog();
    }
}
