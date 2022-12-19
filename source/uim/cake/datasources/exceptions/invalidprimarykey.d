module uim.cake.datasources.exceptions;

@safe:
import uim.cake;

/**
 * Exception raised when the provided primary key does not match the table primary key
 */
class invalidprimaryKeyException : CakeException
{
}
