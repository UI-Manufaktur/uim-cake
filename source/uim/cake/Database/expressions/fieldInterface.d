module uim.cake.databases.expressions;

/**
 * Describes a getter and a setter for the a field property. Useful for expressions
 * that contain an identifier to compare against.
 */
interface FieldInterface
{
    /**
     * Sets the field name
     *
     * @param \Cake\Database\IExpression|array|string myField The field to compare with.
     * @return void
     */
    auto setField(myField): void;

    /**
     * Returns the field name
     *
     * @return \Cake\Database\IExpression|array|string
     */
    auto getField();
}
