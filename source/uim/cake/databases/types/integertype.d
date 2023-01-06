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
    protected void checkNumeric($value) {
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
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     */
    Nullable!int toDatabase($value, IDriver aDriver) {
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
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     */
    Nullable!int toPHP($value, IDriver aDriver) {
        if ($value == null) {
            return null;
        }

        return (int)$value;
    }


    array manyToPHP(array $values, array $fields, IDriver aDriver) {
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
     * @param uim.cake.databases.IDriver aDriver The driver.
     */
    int toStatement($value, IDriver aDriver) {
        return PDO::PARAM_INT;
    }

    /**
     * Marshals request data into PHP integers.
     *
     * @param mixed $value The value to convert.
     * @return int|null Converted value.
     */
    Nullable!int marshal($value) {
        if ($value == null || $value == "") {
            return null;
        }
        if (is_numeric($value)) {
            return (int)$value;
        }

        return null;
    }
}
