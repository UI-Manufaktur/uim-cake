

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

use DateTime;

class DefaultFormatter : AbstractFormatter {
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "dateFormat": "Y-m-d H:i:s",
        "includeTags": false,
        "includeDate": true,
    ];

    /**
     * @param array<string, mixed> aConfig Formatter config
     */
    this(Json aConfig = null) {
        this.setConfig(aConfig);
    }


    string format($level, string $message, array $context = null) {
        if (_config["includeDate"]) {
            $message = sprintf("%s %s: %s", (new DateTime()).format(_config["dateFormat"]), $level, $message);
        } else {
            $message = sprintf("%s: %s", $level, $message);
        }
        if (_config["includeTags"]) {
            $message = sprintf("<%s>%s</%s>", $level, $message, $level);
        }

        return $message;
    }
}
