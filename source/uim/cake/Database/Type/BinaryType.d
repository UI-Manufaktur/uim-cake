module uim.cake.databases.Type;

import uim.cake.core.exceptions.CakeException;
import uim.cake.databases.DriverInterface;
use PDO;

/**
 * Binary type converter.
 *
 * Use to convert binary data between PHP and the database types.
 */
class BinaryType : BaseType
{
    /**
     * Convert binary data into the database format.
     *
     * Binary data is not altered before being inserted into the database.
     * As PDO will handle reading file handles.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return resource|string
     */
    function toDatabase($value, DriverInterface $driver) {
        return $value;
    }

    /**
     * Convert binary into resource handles
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return resource|null
     * @throws uim.cake.Core\exceptions.CakeException
     */
    function toPHP($value, DriverInterface $driver) {
        if ($value == null) {
            return null;
        }
        if (is_string($value)) {
            return fopen("data:text/plain;base64," ~ base64_encode($value), "rb");
        }
        if (is_resource($value)) {
            return $value;
        }
        throw new CakeException(sprintf("Unable to convert %s into binary.", gettype($value)));
    }

    /**
     * Get the correct PDO binding type for Binary data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.DriverInterface $driver The driver.
     */
    int toStatement($value, DriverInterface $driver): int
    {
        return PDO::PARAM_LOB;
    }

    /**
     * Marshals flat data into PHP objects.
     *
     * Most useful for converting request data into PHP objects
     * that make sense for the rest of the ORM/Database layers.
     *
     * @param mixed $value The value to convert.
     * @return mixed Converted value.
     */
    function marshal($value) {
        return $value;
    }
}