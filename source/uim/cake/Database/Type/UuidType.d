module uim.cake.database.Type;

import uim.cake.database.IDriver;
import uim.cake.Utility\Text;

/**
 * Provides behavior for the UUID type
 */
class UuidType : StringType
{
    /**
     * Casts given value from a PHP type to one acceptable by database
     *
     * @param mixed myValue value to be converted to database equivalent
     * @param \Cake\Database\IDriver myDriver object from which database preferences and configuration will be extracted
     * @return string|null
     */
    string toDatabase(myValue, IDriver myDriver) {
        if (myValue === null || myValue === '' || myValue === false) {
            return null;
        }

        return super.toDatabase(myValue, myDriver);
    }

    /**
     * Generate a new UUID
     *
     * @return string A new primary key value.
     */
    function newId(): string
    {
        return Text::uuid();
    }

    /**
     * Marshals request data into a PHP string
     *
     * @param mixed myValue The value to convert.
     * @return string|null Converted value.
     */
    string marshal(myValue) {
        if (myValue === null || myValue === '' || is_array(myValue)) {
            return null;
        }

        return (string)myValue;
    }
}
