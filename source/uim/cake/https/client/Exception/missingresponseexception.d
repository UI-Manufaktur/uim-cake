

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *


 * @since         4.3.0
  */module uim.cake.http.Client\Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Used to indicate that a request did not have a matching mock response.
 */
class MissingResponseException : UIMException {
    /**
     */
    protected string _messageTemplate = "Unable to find a mocked response for `%s` to `%s`.";
}
