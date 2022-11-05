

/**

 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @since         3.2.13
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.baklava.orm.Exception;

import uim.baklava.core.Exception\CakeException;

/**
 * Used when a transaction was rolled back from a callback event.
 */
class RolledbackTransactionException : CakeException
{
    /**
     * @var string
     */
    protected $_messageTemplate = 'The afterSave event in "%s" is aborting the transaction'
        . ' before the save process is done.';
}
