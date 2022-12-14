

/**
 * UIM(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakefoundation.org UIM(tm) Project
 * @since         4.3.0
  */module uim.cake.logs.Formatter;

class JsonFormatter : AbstractFormatter {
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "dateFormat": DATE_ATOM,
        "flags": JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES,
        "appendNewline": true,
    ];

    /**
     * @param array<string, mixed> aConfig Formatter config
     */
    this(Json aConfig = null) {
        this.setConfig(aConfig);
    }


    string format($level, string $message, array $context = null) {
        $log = ["date": date(_config["dateFormat"]), "level": (string)$level, "message": $message];
        $json = json_encode($log, _config["flags"]);

        return _config["appendNewline"] ? $json ~ "\n" : $json;
    }
}
