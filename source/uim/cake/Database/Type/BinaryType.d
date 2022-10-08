module uim.cake.database.Type;

import uim.cake.core.Exception\CakeException;
import uim.cake.database.IDriver;
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
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return resource|string
     */
    function toDatabase(myValue, IDriver myDriver) {
        return myValue;
    }

    /**
     * Convert binary into resource handles
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return resource|null
     * @throws \Cake\Core\Exception\CakeException
     */
    function toPHP(myValue, IDriver myDriver) {
        if (myValue === null) {
            return null;
        }
        if (is_string(myValue)) {
            return fopen('data:text/plain;base64,' . base64_encode(myValue), 'rb');
        }
        if (is_resource(myValue)) {
            return myValue;
        }
        throw new CakeException(sprintf('Unable to convert %s into binary.', gettype(myValue)));
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
}
