/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.logs.engines;

import uim.cake.logs.formatters\DefaultFormatter;

/**
 * Array logger.
 *
 * Collects log messages in memory. Intended primarily for usage
 * in testing where using mocks would be complicated. But can also
 * be used in scenarios where you need to capture logs in application code.
 */
class ArrayLog : BaseLog
{
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "levels":[],
        "scopes":[],
        "formatter":[
            "className":DefaultFormatter::class,
            "includeDate":false,
        ],
    ];

    /**
     * Captured messages
     *
     * @var array
     */
    protected myContents = [];

    /**
     * : writing to the internal storage.
     *
     * @param mixed $level The severity level of log you are making.
     * @param string myMessage The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void success of write.
     * @see \Cake\Log\Log::$_levels
     */
    function log($level, myMessage, array $context = []) {
        myMessage = this._format(myMessage, $context);
        this.content[] = this.formatter.format($level, myMessage, $context);
    }

    // Read the internal storage
    string[] read() {
        return this.content;
    }

    // Reset internal storage.
    void clear() {
        this.content = [];
    }
}
