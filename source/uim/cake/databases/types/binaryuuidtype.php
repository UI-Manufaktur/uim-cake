module uim.cake.databases.types;

import uim.cake.core.exceptions.CakeException;
import uim.cake.databases.IDriver;
import uim.cake.utilities.Text;
use PDO;

/**
 * Binary UUID type converter.
 *
 * Use to convert binary uuid data between PHP and the database types.
 */
class BinaryUuidType : BaseType {
    /**
     * Convert binary uuid data into the database format.
     *
     * Binary data is not altered before being inserted into the database.
     * As PDO will handle reading file handles.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     * @return resource|string|null
     */
    function toDatabase($value, IDriver aDriver) {
        if (!is_string($value)) {
            return $value;
        }

        $length = strlen($value);
        if ($length != 36 && $length != 32) {
            return null;
        }

        return this.convertStringToBinaryUuid($value);
    }

    /**
     * Generate a new binary UUID
     *
     * @return string A new primary key value.
     */
    string newId() {
        return Text::uuid();
    }

    /**
     * Convert binary uuid into resource handles
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     * @return resource|string|null
     * @throws uim.cake.Core\exceptions.CakeException
     */
    function toPHP($value, IDriver aDriver) {
        if ($value == null) {
            return null;
        }
        if (is_string($value)) {
            return this.convertBinaryUuidToString($value);
        }
        if (is_resource($value)) {
            return $value;
        }

        throw new CakeException(sprintf("Unable to convert %s into binary uuid.", gettype($value)));
    }

    /**
     * Get the correct PDO binding type for Binary data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver aDriver The driver.
     */
    int toStatement($value, IDriver aDriver) {
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

    /**
     * Converts a binary uuid to a string representation
     *
     * @param mixed $binary The value to convert.
     * @return string Converted value.
     */
    protected string convertBinaryUuidToString($binary) {
        $string = unpack("H*", $binary);

        $string = preg_replace(
            "/([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})/",
            "$1-$2-$3-$4-$5",
            $string
        );

        return $string[1];
    }

    /**
     * Converts a string UUID (36 or 32 char) to a binary representation.
     *
     * @param string $string The value to convert.
     * @return string Converted value.
     */
    protected string convertStringToBinaryUuid($string) {
        $string = str_replace("-", "", $string);

        return pack("H*", $string);
    }
}
