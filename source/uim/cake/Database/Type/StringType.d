

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.1.2
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.database.Type;

import uim.cake.database.IDriver;
use InvalidArgumentException;
use PDO;

/**
 * String type converter.
 *
 * Use to convert string data between PHP and the database types.
 */
class StringType : BaseType : IOptionalConvert
{
    /**
     * Convert string data into the database format.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return string|null
     */
    string toDatabase(myValue, IDriver myDriver)
    {
        if (myValue === null || is_string(myValue)) {
            return myValue;
        }

        if (is_object(myValue) && method_exists(myValue, '__toString')) {
            return myValue.__toString();
        }

        if (is_scalar(myValue)) {
            return (string)myValue;
        }

        throw new InvalidArgumentException(sprintf(
            'Cannot convert value of type `%s` to string',
            getTypeName(myValue)
        ));
    }

    /**
     * Convert string values to PHP strings.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return string|null
     */
    string toPHP(myValue, IDriver myDriver)
    {
        if (myValue === null) {
            return null;
        }

        return (string)myValue;
    }

    /**
     * Get the correct PDO binding type for string data.
     *
     * @param mixed myValue The value being bound.
     * @param \Cake\Database\IDriver myDriver The driver.
     * @return int
     */
    function toStatement(myValue, IDriver myDriver): int
    {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into PHP strings.
     *
     * @param mixed myValue The value to convert.
     * @return string|null Converted value.
     */
    string marshal(myValue)
    {
        if (myValue === null || is_array(myValue)) {
            return null;
        }

        return (string)myValue;
    }

    /**
     * {@inheritDoc}
     *
     * @return bool False as database results are returned already as strings
     */
    function requiresToPhpCast(): bool
    {
        return false;
    }
}
