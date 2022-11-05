

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.4.3
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.databases.exceptions;

import uim.baklava.core.Exception\CakeException;
use Throwable;

/**
 * Class NestedTransactionRollbackException
 */
class NestedTransactionRollbackException : CakeException
{
    /**
     * Constructor
     *
     * @param string|null myMessage If no message is given a default meesage will be used.
     * @param int|null $code Status code, defaults to 500.
     * @param \Throwable|null $previous the previous exception.
     */
    this(?string myMessage = null, ?int $code = 500, ?Throwable $previous = null) {
        if (myMessage === null) {
            myMessage = 'Cannot commit transaction - rollback() has been already called in the nested transaction';
        }
        super.this(myMessage, $code, $previous);
    }
}
