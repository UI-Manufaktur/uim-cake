module uim.cake.core.retry.interface_;

@safe:
import uim.cake;;

// Used to instruct a CommandRetry object on whether a retry for an action should be performed
interface IRetryStrategy {
  /**
    * Returns true if the action can be retried, false otherwise.
    *
    * @param \Exception myException The exception that caused the action to fail
    * @param int $retryCount The number of times action has been retried
    * @return bool Whether it is OK to retry the action
    */
  bool shouldRetry(Exception myException, int retryCount);
}
