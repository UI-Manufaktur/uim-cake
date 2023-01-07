

/**
 * MissingEntityException file
 *
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *



  */module uim.cake.orm.Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Exception raised when an Entity could not be found.
 */
class MissingEntityException : UIMException {
    /**
     */
    protected string _messageTemplate = "Entity class %s could not be found.";
}
