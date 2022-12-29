


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Expression;

/**
 * Describes a getter and a setter for the a field property. Useful for expressions
 * that contain an identifier to compare against.
 */
interface FieldInterface
{
    /**
     * Sets the field name
     *
     * @param \Cake\Database\IExpression|array|string $field The field to compare with.
     * @return void
     */
    function setField($field): void;

    /**
     * Returns the field name
     *
     * @return \Cake\Database\IExpression|array|string
     */
    function getField();
}
