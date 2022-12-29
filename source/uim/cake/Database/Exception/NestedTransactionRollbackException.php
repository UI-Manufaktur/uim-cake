


 *


 * @since         3.4.3
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Exception;

import uim.cake.cores.exceptions.CakeException;
use Throwable;

/**
 * Class NestedTransactionRollbackException
 */
class NestedTransactionRollbackException : CakeException
{
    /**
     * Constructor
     *
     * @param string|null $message If no message is given a default meesage will be used.
     * @param int|null $code Status code, defaults to 500.
     * @param \Throwable|null $previous the previous exception.
     */
    public this(?string $message = null, ?int $code = 500, ?Throwable $previous = null) {
        if ($message == null) {
            $message = "Cannot commit transaction - rollback() has been already called in the nested transaction";
        }
        super(($message, $code, $previous);
    }
}
