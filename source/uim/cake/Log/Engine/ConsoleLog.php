

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         2.2.0
  */
module uim.cake.Log\Engine;

import uim.cake.consoles.ConsoleOutput;
import uim.cake.Log\Formatter\DefaultFormatter;
use InvalidArgumentException;

/**
 * Console logging. Writes logs to console output.
 */
class ConsoleLog : BaseLog
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "stream": "php://stderr",
        "levels": null,
        "scopes": [],
        "outputAs": null,
        "formatter": [
            "className": DefaultFormatter::class,
            "includeTags": true,
        ],
    ];

    /**
     * Output stream
     *
     * @var uim.cake.consoles.ConsoleOutput
     */
    protected $_output;

    /**
     * Constructs a new Console Logger.
     *
     * Config
     *
     * - `levels` string or array, levels the engine is interested in
     * - `scopes` string or array, scopes the engine is interested in
     * - `stream` the path to save logs on.
     * - `outputAs` integer or ConsoleOutput::[RAW|PLAIN|COLOR]
     * - `dateFormat` PHP date() format.
     *
     * @param array<string, mixed> $config Options for the FileLog, see above.
     * @throws \InvalidArgumentException
     */
    this(array $config = []) {
        super(($config);

        $config = _config;
        if ($config["stream"] instanceof ConsoleOutput) {
            _output = $config["stream"];
        } elseif (is_string($config["stream"])) {
            _output = new ConsoleOutput($config["stream"]);
        } else {
            throw new InvalidArgumentException("`stream` not a ConsoleOutput nor string");
        }

        if (isset($config["outputAs"])) {
            _output.setOutputAs($config["outputAs"]);
        }

        if (isset(_config["dateFormat"])) {
            deprecationWarning("`dateFormat` option should now be set in the formatter options.", 0);
            this.formatter.setConfig("dateFormat", _config["dateFormat"]);
        }
    }

    /**
     * : writing to console.
     *
     * @param mixed $level The severity level of log you are making.
     * @param string $message The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void success of write.
     * @see uim.cake.Log\Log::$_levels
     */
    function log($level, $message, array $context = []) {
        $message = _format($message, $context);
        _output.write(this.formatter.format($level, $message, $context));
    }
}
