module uim.cake.databases.exceptions.nestedtransactionrollback;

@safe:
import uim.cake;

use Throwable;

/**
 * Class NestedTransactionRollbackException
 */
class NestedTransactionRollbackException : CakeException {
    /**
     * Constructor
     *
     * @param string|null $message If no message is given a default meesage will be used.
     * @param int|null $code Status code, defaults to 500.
     * @param \Throwable|null $previous the previous exception.
     */
    this(?string $message = null, Nullable!int $code = 500, ?Throwable $previous = null) {
        if ($message == null) {
            $message = "Cannot commit transaction - rollback() has been already called in the nested transaction";
        }
        super(($message, $code, $previous);
    }
}
