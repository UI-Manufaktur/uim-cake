/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.logs.engines;

@safe:
import uim.cake;

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
    protected STRINGAA _defaultConfig = [
        "stream":"php://stderr",
        "levels":null,
        "scopes":[],
        "outputAs":null,
        "formatter":[
            "className":DefaultFormatter::class,
            "includeTags":true,
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
     * @param array<string, mixed> myConfig Options for the FileLog, see above.
     * @throws \InvalidArgumentException
     */
    this(array myConfig = null) {
        super.this(myConfig);

        myConfig = _config;
        if (myConfig["stream"] instanceof ConsoleOutput) {
            _output = myConfig["stream"];
        } elseif (is_string(myConfig["stream"])) {
            _output = new ConsoleOutput(myConfig["stream"]);
        } else {
            throw new InvalidArgumentException("`stream` not a ConsoleOutput nor string");
        }

        if (isset(myConfig["outputAs"])) {
            _output.setOutputAs(myConfig["outputAs"]);
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
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void success of write.
     * @see uim.cake.logs.Log::_levels
     */
    function log($level, myMessage, array $context = null) {
        myMessage = _format(myMessage, $context);
        _output.write(this.formatter.format($level, myMessage, $context));
    }
}
