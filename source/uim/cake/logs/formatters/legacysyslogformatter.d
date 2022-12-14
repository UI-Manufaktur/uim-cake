

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

/**
 * @deprecated 4.3.0 Create a custom formatter and set it with `formatter` config instead.
 */
class LegacySyslogFormatter : AbstractFormatter {
    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
        "format": "%s: %s",
    ];

    /**
     * @param array<string, mixed> aConfig Formatter config
     */
    this(Json aConfig = null) {
        this.setConfig(aConfig);
    }


    string format($level, string $message, array $context = null) {
        return sprintf(this.getConfig("format"), $level, $message);
    }
}
