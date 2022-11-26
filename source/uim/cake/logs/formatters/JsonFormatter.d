

/**
 * UIM(tm) :  Rapid Development Framework (https://UIM.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org UIM(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs.formatters;

class JsonFormatter : AbstractFormatter
{
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
