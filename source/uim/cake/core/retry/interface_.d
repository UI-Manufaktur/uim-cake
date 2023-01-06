/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.core.retry.interface_;

@safe:
import uim.cake;

use Exception;

/**
 * Used to instruct a CommandRetry object on whether a retry
 * for an action should be performed
 */
interface RetryStrategyInterface
{
    /**
     * Returns true if the action can be retried, false otherwise.
     *
     * @param \Exception $exception The exception that caused the action to fail
     * @param int $retryCount The number of times action has been retried
     * @return bool Whether it is OK to retry the action
     */
    bool shouldRetry(Exception $exception, int $retryCount);
}

