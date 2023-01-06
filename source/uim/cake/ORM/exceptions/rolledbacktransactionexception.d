

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *

 * @since         3.2.13
  */module uim.cake.orm.Exception;

import uim.cake.core.exceptions.CakeException;

/**
 * Used when a transaction was rolled back from a callback event.
 */
class RolledbackTransactionException : CakeException {
    /**
     */
    protected string _messageTemplate = "The afterSave event in "%s" is aborting the transaction"
        ~ " before the save process is done.";
}
