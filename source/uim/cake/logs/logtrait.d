

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.logs;

use Psr\Log\LogLevel;

/**
 * A trait providing an object short-cut method
 * to logging.
 */
trait LogTrait
{
    /**
     * Convenience method to write a message to Log. See Log::write()
     * for more information on writing to logs.
     *
     * @param string myMessage Log message.
     * @param string|int $level Error level.
     * @param array|string $context Additional log data relevant to this message.
     * @return bool Success of log write.
     */
    bool log(string myMessage, $level = LogLevel::ERROR, $context = []) {
        return Log::write($level, myMessage, $context);
    }
}
