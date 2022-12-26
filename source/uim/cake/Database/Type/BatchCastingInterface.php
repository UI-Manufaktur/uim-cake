


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;

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
     * @param \Cake\Database\DriverInterface $driver Object from which database preferences and configuration will be extracted.
     * @return array<string, mixed>
     */
    function manyToPHP(array $values, array $fields, DriverInterface $driver): array;
}
