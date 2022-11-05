module uim.baklava.databases.exceptions;

import uim.baklava.core.Exception\CakeException;

/**
 * Exception for the database package.
 */
class DatabaseException : CakeException
{
}

// phpcs:disable
class_exists('Cake\Database\Exception');
// phpcs:enable
