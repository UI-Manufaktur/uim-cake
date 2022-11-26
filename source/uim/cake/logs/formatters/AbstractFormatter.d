

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakefoundation.org CakePHP(tm) Project
 * @since         4.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs.formatters;

import uim.cake.core.InstanceConfigTrait;

abstract class AbstractFormatter
{
    use InstanceConfigTrait;

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
    ];

    /**
     * @param array<string, mixed> myConfig Config options
     */
    this(array myConfig = []) {
        this.setConfig(myConfig);
    }

    /**
     * Formats message.
     *
     * @param mixed $level Logging level
     * @param string myMessage Message string
     * @param array $context Mesage context
     * @return string Formatted message
     */
    abstract string format($level, string myMessage, array $context = []);
}
