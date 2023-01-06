module uim.cake.databases.types;

import uim.cake.databases.IDriver;

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
     * @param array $values The original array of values containing the fields to be casted
     * @param array<string> $fields The field keys to cast
     * @param uim.cake.databases.IDriver aDriver Object from which database preferences and configuration will be extracted.
     * @return array<string, mixed>
     */
    array manyToPHP(array $values, array $fields, IDriver aDriver);
}
