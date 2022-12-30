/*********************************************************************************************************
*	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        *
*	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  *
*	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      *
**********************************************************************************************************/module uim.cake.logs.formatters.abtract_;

@safe:
import uim.cake;

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
