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
     * @param \Cake\Database\IExpression|array|string myField The field to compare with.
     * @return void
     */
    auto setField(myField): void
    {
        this._field = myField;
    }

    /**
     * Returns the field name
     *
     * @return \Cake\Database\IExpression|array|string
     */
    auto getField() {
        return this._field;
    }
}
