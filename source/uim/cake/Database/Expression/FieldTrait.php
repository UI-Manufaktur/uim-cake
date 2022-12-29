


 *


 * @since         3.0.0
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
     * @var uim.cake.Database\IExpression|array|string
     */
    protected $_field;

    /**
     * Sets the field name
     *
     * @param uim.cake.Database\IExpression|array|string $field The field to compare with.
     * @return void
     */
    function setField($field): void
    {
        _field = $field;
    }

    /**
     * Returns the field name
     *
     * @return uim.cake.Database\IExpression|array|string
     */
    function getField() {
        return _field;
    }
}
