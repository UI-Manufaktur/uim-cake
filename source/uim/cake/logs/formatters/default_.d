/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.logs.formatters.default_;

@safe:
import uim.cake;

class DefaultFormatter : AbstractFormatter {
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "dateFormat":"Y-m-d H:i:s",
        "includeTags":false,
        "includeDate":true,
    ];

    /**
     * @param array<string, mixed> myConfig Formatter config
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }

    string format($level, string myMessage, array $context = []) {
        if (_config["includeDate"]) {
            myMessage = sprintf("%s %s: %s", date(_config["dateFormat"]), $level, myMessage);
        } else {
            myMessage = sprintf("%s: %s", $level, myMessage);
        }
        if (_config["includeTags"]) {
            myMessage = sprintf("<%s>%s</%s>", $level, myMessage, $level);
        }

        return myMessage;
    }
}
