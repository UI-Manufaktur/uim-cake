

/**
 * CakePHP(tm) :  Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *

 * @link          https://cakefoundation.org CakePHP(tm) Project

  */
module uim.cake.logs.Engine;

import uim.cake.logs.Formatter\DefaultFormatter;

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
    protected $_defaultConfig = [
        "levels": [],
        "scopes": [],
        "formatter": [
            "className": DefaultFormatter::class,
            "includeDate": false,
        ],
    ];

    /**
     * Captured messages
     *
     * @var array<string>
     */
    protected $content = [];

    /**
     * : writing to the internal storage.
     *
     * @param mixed $level The severity level of log you are making.
     * @param string $message The message you want to log.
     * @param array $context Additional information about the logged message
     * @return void success of write.
     * @see uim.cake.logs.Log::$_levels
     */
    function log($level, $message, array $context = []) {
        $message = _format($message, $context);
        this.content[] = this.formatter.format($level, $message, $context);
    }

    /**
     * Read the internal storage
     *
     * @return array<string>
     */
    function read(): array
    {
        return this.content;
    }

    /**
     * Reset internal storage.
     */
    void clear(): void
    {
        this.content = [];
    }
}
