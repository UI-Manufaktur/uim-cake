/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.logs.Engine;

import uim.cake.consoles.ConsoleOutput;
import uim.cake.logs.Formatter\DefaultFormatter;
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
    protected _defaultConfig = [
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
    protected _output;

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
     * @param array<string, mixed> aConfig Options for the FileLog, see above.
     * @throws \InvalidArgumentException
     */
    this(Json aConfig = null) {
        super((aConfig);

        aConfig = _config;
        if (aConfig["stream"] instanceof ConsoleOutput) {
            _output = aConfig["stream"];
        } elseif (is_string(aConfig["stream"])) {
            _output = new ConsoleOutput(aConfig["stream"]);
        } else {
            throw new InvalidArgumentException("`stream` not a ConsoleOutput nor string");
        }

        if (isset(aConfig["outputAs"])) {
            _output.setOutputAs(aConfig["outputAs"]);
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
     * @see uim.cake.logs.Log::_levels
     */
    function log($level, $message, array $context = null) {
        $message = _format($message, $context);
        _output.write(this.formatter.format($level, $message, $context));
    }
}
