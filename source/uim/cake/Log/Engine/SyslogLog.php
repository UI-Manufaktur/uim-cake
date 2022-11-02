

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         2.4.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Log\Engine;

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
     *  Log::config('error', ]
     *      'engine' => 'Syslog',
     *      'levels' => ['emergency', 'alert', 'critical', 'error'],
     *      'prefix' => 'Web Server 01'
     *  ]);
     * ```
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'levels' => [],
        'scopes' => [],
        'flag' => LOG_ODELAY,
        'prefix' => '',
        'facility' => LOG_USER,
        'formatter' => [
            'className' => DefaultFormatter::class,
            'includeDate' => false,
        ],
    ];

    /**
     * Used to map the string names back to their LOG_* constants
     *
     * @var array<int>
     */
    protected $_levelMap = [
        'emergency' => LOG_EMERG,
        'alert' => LOG_ALERT,
        'critical' => LOG_CRIT,
        'error' => LOG_ERR,
        'warning' => LOG_WARNING,
        'notice' => LOG_NOTICE,
        'info' => LOG_INFO,
        'debug' => LOG_DEBUG,
    ];

    /**
     * Whether the logger connection is open or not
     *
     * @var bool
     */
    protected $_open = false;


    this(array myConfig = []) {
        if (isset(myConfig['format'])) {
            deprecationWarning(
                '`format` option is now deprecated in favor of custom formatters. ' .
                'Switching to `LegacySyslogFormatter`.',
                0
            );
            /** @psalm-suppress DeprecatedClass */
            myConfig['formatter'] = [
                'className' => LegacySyslogFormatter::class,
                'format' => myConfig['format'],
            ];
        }
        super.this(myConfig);
    }

    /**
     * Writes a message to syslog
     *
     * Map the $level back to a LOG_ constant value, split multi-line messages into multiple
     * log messages, pass all messages through the format defined in the configuration
     *
     * @param mixed $level The severity level of log you are making.
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void
     * @see \Cake\Log\Log::$_levels
     */
    function log($level, myMessage, array $context = []): void
    {
        if (!this._open) {
            myConfig = this._config;
            this._open(myConfig['prefix'], myConfig['flag'], myConfig['facility']);
            this._open = true;
        }

        $priority = LOG_DEBUG;
        if (isset(this._levelMap[$level])) {
            $priority = this._levelMap[$level];
        }

        $lines = explode("\n", this._format(myMessage, $context));
        foreach ($lines as $line) {
            this._write($priority, this.formatter.format($level, $line, $context));
        }
    }

    /**
     * Extracts the call to openlog() in order to run unit tests on it. This function
     * will initialize the connection to the system logger
     *
     * @param string $ident the prefix to add to all messages logged
     * @param int myOptions the options flags to be used for logged messages
     * @param int $facility the stream or facility to log to
     * @return void
     */
    protected auto _open(string $ident, int myOptions, int $facility): void
    {
        openlog($ident, myOptions, $facility);
    }

    /**
     * Extracts the call to syslog() in order to run unit tests on it. This function
     * will perform the actual write in the system logger
     *
     * @param int $priority Message priority.
     * @param string myMessage Message to log.
     * @return bool
     */
    protected bool _write(int $priority, string myMessage)
    {
        return syslog($priority, myMessage);
    }

    /**
     * Closes the logger connection
     */
    auto __destruct() {
        closelog();
    }
}
