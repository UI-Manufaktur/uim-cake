


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Expression;

/**
 * Contains the field property with a getter and a setter for it
 */
trait FieldTrait
{
    /**
     * The field name or expression to be used in the left hand side of the operator
     *
     * @var \Cake\Database\IExpression|array|string
     */
    protected $_field;

    /**
     * Sets the field name
     *
     * @param \Cake\Database\IExpression|array|string $field The field to compare with.
     * @return void
     */
    function setField($field): void
    {
        _field = $field;
    }

    /**
     * Returns the field name
     *
     * @return \Cake\Database\IExpression|array|string
     */
    function getField() {
        return _field;
    }
}
