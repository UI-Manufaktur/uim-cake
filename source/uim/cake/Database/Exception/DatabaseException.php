module uim.cake.database.Exception;

import uim.cake.core.Exception\CakeException;

/**
 * Exception for the database package.
 */
class DatabaseException : CakeException
{
}

// phpcs:disable
class_exists('Cake\Database\Exception');
// phpcs:enable
