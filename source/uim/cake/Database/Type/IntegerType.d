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
     * @param mixed myValue Value to check
     * @return void
     */
    protected auto checkNumeric(myValue): void
    {
        if (!is_numeric(myValue)) {
            throw new InvalidArgumentException(sprintf(
                'Cannot convert value of type `%s` to integer',
                getTypeName(myValue)
            ));
        }
    }

    /**
     * Convert integer data into the database format.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return int|null
     */
    function toDatabase(myValue, IDriver myDriver): ?int
    {
        if (myValue === null || myValue === '') {
            return null;
        }

        this.checkNumeric(myValue);

        return (int)myValue;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return int|null
     */
    function toPHP(myValue, IDriver myDriver): ?int
    {
        if (myValue === null) {
            return null;
        }

        return (int)myValue;
    }


    function manyToPHP(array myValues, array myFields, IDriver myDriver): array
    {
        foreach (myFields as myField) {
            if (!isset(myValues[myField])) {
                continue;
            }

            this.checkNumeric(myValues[myField]);

            myValues[myField] = (int)myValues[myField];
        }

        return myValues;
    }

    /**
     * Get the correct PDO binding type for integer data.
     *
     * @param mixed myValue The value being bound.
     * @param \Cake\Database\IDriver myDriver The driver.
     * @return int
     */
    function toStatement(myValue, IDriver myDriver): int
    {
        return PDO::PARAM_INT;
    }

    /**
     * Marshals request data into PHP floats.
     *
     * @param mixed myValue The value to convert.
     * @return int|null Converted value.
     */
    function marshal(myValue): ?int
    {
        if (myValue === null || myValue === '') {
            return null;
        }
        if (is_numeric(myValue)) {
            return (int)myValue;
        }

        return null;
    }
}
