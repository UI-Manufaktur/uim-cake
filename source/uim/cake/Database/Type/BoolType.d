

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
 * Bool type converter.
 *
 * Use to convert bool data between PHP and the database types.
 */
class BoolType : BaseType : BatchCastingInterface
{
    /**
     * Convert bool data into the database format.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return bool|null
     */
    function toDatabase(myValue, IDriver myDriver): ?bool
    {
        if (myValue === true || myValue === false || myValue === null) {
            return myValue;
        }

        if (in_array(myValue, [1, 0, '1', '0'], true)) {
            return (bool)myValue;
        }

        throw new InvalidArgumentException(sprintf(
            'Cannot convert value of type `%s` to bool',
            getTypeName(myValue)
        ));
    }

    /**
     * Convert bool values to PHP booleans
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return bool|null
     */
    function toPHP(myValue, IDriver myDriver): ?bool
    {
        if (myValue === null || myValue === true || myValue === false) {
            return myValue;
        }

        if (!is_numeric(myValue)) {
            return strtolower(myValue) === 'true';
        }

        return !empty(myValue);
    }


    function manyToPHP(array myValues, array myFields, IDriver myDriver): array
    {
        foreach (myFields as myField) {
            if (!isset(myValues[myField]) || myValues[myField] === true || myValues[myField] === false) {
                continue;
            }

            if (myValues[myField] === '1') {
                myValues[myField] = true;
                continue;
            }

            if (myValues[myField] === '0') {
                myValues[myField] = false;
                continue;
            }

            myValue = myValues[myField];
            if (!is_numeric(myValue)) {
                myValues[myField] = strtolower(myValue) === 'true';
                continue;
            }

            myValues[myField] = !empty(myValue);
        }

        return myValues;
    }

    /**
     * Get the correct PDO binding type for bool data.
     *
     * @param mixed myValue The value being bound.
     * @param \Cake\Database\IDriver myDriver The driver.
     * @return int
     */
    function toStatement(myValue, IDriver myDriver): int
    {
        if (myValue === null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_BOOL;
    }

    /**
     * Marshals request data into PHP booleans.
     *
     * @param mixed myValue The value to convert.
     * @return bool|null Converted value.
     */
    function marshal(myValue): ?bool
    {
        if (myValue === null || myValue === '') {
            return null;
        }

        return filter_var(myValue, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
    }
}
