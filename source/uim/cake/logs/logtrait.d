/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.logs;

use Psr\logs.LogLevel;

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
     * @param array|string context Additional log data relevant to this message.
     * @return bool Success of log write.
     */
    bool log(string myMessage, $level = LogLevel::ERROR, $context = []) {
        return Log::write($level, myMessage, $context);
    }
}
