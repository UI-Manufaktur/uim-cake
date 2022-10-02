module uim.cake.database.Type;

import uim.cake.database.IDriver;

/**
 * Denotes type objects capable of converting many values from their original
 * database representation to php values.
 */
interface BatchCastingInterface
{
    /**
     * Returns an array of the values converted to the PHP representation of
     * this type.
     *
     * @param array myValues The original array of values containing the fields to be casted
     * @param array<string> myFields The field keys to cast
     * @param \Cake\Database\IDriver myDriver Object from which database preferences and configuration will be extracted.
     * @return array
     */
    function manyToPHP(array myValues, array myFields, IDriver myDriver): array;
}
