module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
use InvalidArgumentException;
use PDO;

/**
 * Integer type converter.
 *
 * Use to convert integer data between PHP and the database types.
 */
class IntegerType : BaseType : BatchCastingInterface
{
    /**
     * Checks if the value is not a numeric value
     *
     * @throws \InvalidArgumentException
     * @param mixed $value Value to check
     */
    protected void checkNumeric($value)
    {
        if (!is_numeric($value)) {
            throw new InvalidArgumentException(sprintf(
                "Cannot convert value of type `%s` to integer",
                getTypeName($value)
            ));
        }
    }

    /**
     * Convert integer data into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver $driver The driver instance to convert with.
     * @return int|null
     */
    function toDatabase($value, IDriver $driver): ?int
    {
        if ($value == null || $value == "") {
            return null;
        }

        this.checkNumeric($value);

        return (int)$value;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver $driver The driver instance to convert with.
     * @return int|null
     */
    function toPHP($value, IDriver $driver): ?int
    {
        if ($value == null) {
            return null;
        }

        return (int)$value;
    }


    function manyToPHP(array $values, array $fields, IDriver $driver): array
    {
        foreach ($fields as $field) {
            if (!isset($values[$field])) {
                continue;
            }

            this.checkNumeric($values[$field]);

            $values[$field] = (int)$values[$field];
        }

        return $values;
    }

    /**
     * Get the correct PDO binding type for integer data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver $driver The driver.
     */
    int toStatement($value, IDriver $driver): int
    {
        return PDO::PARAM_INT;
    }

    /**
     * Marshals request data into PHP integers.
     *
     * @param mixed $value The value to convert.
     * @return int|null Converted value.
     */
    function marshal($value): ?int
    {
        if ($value == null || $value == "") {
            return null;
        }
        if (is_numeric($value)) {
            return (int)$value;
        }

        return null;
    }
}
