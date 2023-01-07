

/**
 * UIM(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * Redistributions of files must retain the above copyright notice.
 *module uim.cake.datasources.Paging\Exception;

import uim.cake.core.exceptions.UIMException;

/**
 * Exception raised when requested page number does not exist.
 */
class PageOutOfBoundsException : UIMException {

    protected _messageTemplate = "Page number %s could not be found.";
}

// phpcs:disable
class_exists("Cake\Datasource\exceptions.PageOutOfBoundsException");
// phpcs:enable
