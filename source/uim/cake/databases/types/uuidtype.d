module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
import uim.cake.utilities.Text;

/**
 * Provides behavior for the UUID type
 */
class UuidType : StringType
{
    /**
     * Casts given value from a PHP type to one acceptable by database
     *
     * @param mixed $value value to be converted to database equivalent
     * @param uim.cake.databases.IDriver $driver object from which database preferences and configuration will be extracted
     */
    Nullable!string toDatabase($value, IDriver $driver)
    {
        if ($value == null || $value == "" || $value == false) {
            return null;
        }

        return super.toDatabase($value, $driver);
    }

    /**
     * Generate a new UUID
     *
     * @return string A new primary key value.
     */
    string newId() {
        return Text::uuid();
    }

    /**
     * Marshals request data into a PHP string
     *
     * @param mixed $value The value to convert.
     * @return string|null Converted value.
     */
    Nullable!string marshal($value)
    {
        if ($value == null || $value == "" || is_array($value)) {
            return null;
        }

        return (string)$value;
    }
}
