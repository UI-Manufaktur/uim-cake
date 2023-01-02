module uim.cake.databases.exceptions;

import uim.cake.core.exceptions.CakeException;

/**
 * Exception for the database package.
 */
class DatabaseException : CakeException
{
}

// phpcs:disable
class_exists("Cake\databases.exceptions");
// phpcs:enable
