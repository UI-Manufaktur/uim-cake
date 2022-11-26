

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         2.2.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs.engines;

import uim.cake.console.consoleOutput;
import uim.cake.logs.formatters\DefaultFormatter;
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
     * @var \Cake\Console\ConsoleOutput
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
     * @param array<string, mixed> myConfig Options for the FileLog, see above.
     * @throws \InvalidArgumentException
     */
    this(array myConfig = []) {
        super.this(myConfig);

        myConfig = this._config;
        if (myConfig["stream"] instanceof ConsoleOutput) {
            this._output = myConfig["stream"];
        } elseif (is_string(myConfig["stream"])) {
            this._output = new ConsoleOutput(myConfig["stream"]);
        } else {
            throw new InvalidArgumentException("`stream` not a ConsoleOutput nor string");
        }

        if (isset(myConfig["outputAs"])) {
            this._output.setOutputAs(myConfig["outputAs"]);
        }

        if (isset(this._config["dateFormat"])) {
            deprecationWarning("`dateFormat` option should now be set in the formatter options.", 0);
            this.formatter.setConfig("dateFormat", this._config["dateFormat"]);
        }
    }

    /**
     * : writing to console.
     *
     * @param mixed $level The severity level of log you are making.
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void success of write.
     * @see \Cake\Log\Log::$_levels
     */
    function log($level, myMessage, array $context = []) {
        myMessage = this._format(myMessage, $context);
        this._output.write(this.formatter.format($level, myMessage, $context));
    }
}
