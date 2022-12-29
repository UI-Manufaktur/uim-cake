


 *


 * @since         3.0.0
  */
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
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
     * @param uim.cake.Database\DriverInterface $driver object from which database preferences and configuration will be extracted
     * @return string|null
     */
    function toDatabase($value, DriverInterface $driver): ?string
    {
        if ($value == null || $value == "" || $value == false) {
            return null;
        }

        return parent::toDatabase($value, $driver);
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
     * @param mixed $value The value to convert.
     * @return string|null Converted value.
     */
    function marshal($value): ?string
    {
        if ($value == null || $value == "" || is_array($value)) {
            return null;
        }

        return (string)$value;
    }
}
