module uim.cake.databases.Type;

import uim.cake.core.Exception\CakeException;
import uim.cake.databases.IDriver;
import uim.cake.Utility\Text;
use PDO;

/**
 * Binary UUID type converter.
 *
 * Use to convert binary uuid data between PHP and the database types.
 */
class BinaryUuidType : BaseType
{
    /**
     * Convert binary uuid data into the database format.
     *
     * Binary data is not altered before being inserted into the database.
     * As PDO will handle reading file handles.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return resource|string|null
     */
    function toDatabase(myValue, IDriver myDriver) {
        if (!is_string(myValue)) {
            return myValue;
        }

        $length = strlen(myValue);
        if ($length !== 36 && $length !== 32) {
            return null;
        }

        return this.convertStringToBinaryUuid(myValue);
    }

    /**
     * Generate a new binary UUID
     *
     * @return string A new primary key value.
     */
    function newId(): string
    {
        return Text::uuid();
    }

    /**
     * Convert binary uuid into resource handles
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return resource|string|null
     * @throws \Cake\Core\Exception\CakeException
     */
    function toPHP(myValue, IDriver myDriver) {
        if (myValue === null) {
            return null;
        }
        if (is_string(myValue)) {
            return this.convertBinaryUuidToString(myValue);
        }
        if (is_resource(myValue)) {
            return myValue;
        }

        throw new CakeException(sprintf('Unable to convert %s into binary uuid.', gettype(myValue)));
    }

    /**
     * Get the correct PDO binding type for Binary data.
     *
     * @param mixed myValue The value being bound.
     * @param \Cake\Database\IDriver myDriver The driver.
     * @return int
     */
    function toStatement(myValue, IDriver myDriver): int
    {
        return PDO::PARAM_LOB;
    }

    /**
     * Marshals flat data into PHP objects.
     *
     * Most useful for converting request data into PHP objects
     * that make sense for the rest of the ORM/Database layers.
     *
     * @param mixed myValue The value to convert.
     * @return mixed Converted value.
     */
    function marshal(myValue) {
        return myValue;
    }

    /**
     * Converts a binary uuid to a string representation
     *
     * @param mixed $binary The value to convert.
     * @return string Converted value.
     */
    protected auto convertBinaryUuidToString($binary): string
    {
        $string = unpack('H*', $binary);

        $string = preg_replace(
            '/([0-9a-f]{8})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{4})([0-9a-f]{12})/',
            '$1-$2-$3-$4-$5',
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
    protected auto convertStringToBinaryUuid($string): string
    {
        $string = str_replace('-', '', $string);

        return pack('H*', $string);
    }
}
