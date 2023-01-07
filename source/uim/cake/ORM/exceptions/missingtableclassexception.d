

/**
 * MissingTableClassException class
 *
 * UIM(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


  */module uim.cake.orm.Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Exception raised when a Table could not be found.
 */
class MissingTableClassException : UIMException {
    /**
     */
    protected string _messageTemplate = "Table class %s could not be found.";
}
