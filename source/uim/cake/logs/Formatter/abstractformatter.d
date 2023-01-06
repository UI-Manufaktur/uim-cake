

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         4.3.0
  */module uim.cake.logs.Formatter;

import uim.cake.core.InstanceConfigTrait;

abstract class AbstractFormatter
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected _defaultConfig = [
    ];

    /**
     * @param array<string, mixed> aConfig Config options
     */
    this(Json aConfig = []) {
        this.setConfig(aConfig);
    }

    /**
     * Formats message.
     *
     * @param mixed $level Logging level
     * @param string $message Message string
     * @param array $context Mesage context
     * @return string Formatted message
     */
    abstract string format($level, string $message, array $context = []);
}
