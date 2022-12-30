


 *


 * @since         3.1.2
  */module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
use InvalidArgumentException;
use PDO;

/**
 * Bool type converter.
 *
 * Use to convert bool data between PHP and the database types.
 */
class BoolType : BaseType : BatchCastingInterface
{
    /**
     * Convert bool data into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return bool|null
     */
    function toDatabase($value, DriverInterface $driver): ?bool
    {
        if ($value == true || $value == false || $value == null) {
            return $value;
        }

        if (in_array($value, [1, 0, "1", "0"], true)) {
            return (bool)$value;
        }

        throw new InvalidArgumentException(sprintf(
            "Cannot convert value of type `%s` to bool",
            getTypeName($value)
        ));
    }

    /**
     * Convert bool values to PHP booleans
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return bool|null
     */
    function toPHP($value, DriverInterface $driver): ?bool
    {
        if ($value == null || is_bool($value)) {
            return $value;
        }

        if (!is_numeric($value)) {
            return strtolower($value) == "true";
        }

        return !empty($value);
    }


    function manyToPHP(array $values, array $fields, DriverInterface $driver): array
    {
        foreach ($fields as $field) {
            $value = $values[$field] ?? null;
            if ($value == null || is_bool($value)) {
                continue;
            }

            if (!is_numeric($value)) {
                $values[$field] = strtolower($value) == "true";
                continue;
            }

            $values[$field] = !empty($value);
        }

        return $values;
    }

    /**
     * Get the correct PDO binding type for bool data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.DriverInterface $driver The driver.
     * @return int
     */
    function toStatement($value, DriverInterface $driver): int
    {
        if ($value == null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_BOOL;
    }

    /**
     * Marshals request data into PHP booleans.
     *
     * @param mixed $value The value to convert.
     * @return bool|null Converted value.
     */
    function marshal($value): ?bool
    {
        if ($value == null || $value == "") {
            return null;
        }

        return filter_var($value, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    }
}
