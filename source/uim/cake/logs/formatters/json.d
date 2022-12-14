/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/
module uim.cake.logs.formatters.json;

@safe:
import uim.cake;

class JsonFormatter : AbstractFormatter {
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "dateFormat":DATE_ATOM,
        "flags":JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES,
        "appendNewline":true,
    ];

    /**
     * @param array<string, mixed> myConfig Formatter config
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }


    string format($level, string myMessage, array $context = []) {
        $log = ["date":date(this._config["dateFormat"]), "level":(string)$level, "message":myMessage];
        $json = json_encode($log, this._config["flags"]);

        return this._config["appendNewline"] ? $json . "\n" : $json;
    }
}
