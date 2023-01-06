/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
use InvalidArgumentException;
use PDO;

/**
 * String type converter.
 *
 * Use to convert string data between PHP and the database types.
 */
class StringType : BaseType : OptionalConvertInterface
{
    /**
     * Convert string data into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     */
    Nullable!string toDatabase($value, IDriver aDriver) {
        if ($value == null || is_string($value)) {
            return $value;
        }

        if (is_object($value) && method_exists($value, "__toString")) {
            return $value.__toString();
        }

        if (is_scalar($value)) {
            return (string)$value;
        }

        throw new InvalidArgumentException(sprintf(
            "Cannot convert value of type `%s` to string",
            getTypeName($value)
        ));
    }

    /**
     * Convert string values to PHP strings.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     */
    Nullable!string toPHP($value, IDriver aDriver) {
        if ($value == null) {
            return null;
        }

        return (string)$value;
    }

    /**
     * Get the correct PDO binding type for string data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver aDriver The driver.
     */
    int toStatement($value, IDriver aDriver) {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into PHP strings.
     *
     * @param mixed $value The value to convert.
     * @return string|null Converted value.
     */
    Nullable!string marshal($value) {
        if ($value == null || is_array($value)) {
            return null;
        }

        return (string)$value;
    }

    /**
     * {@inheritDoc}
     *
     * @return bool False as database results are returned already as strings
     */
    bool requiresToPhpCast() {
        return false;
    }
}
