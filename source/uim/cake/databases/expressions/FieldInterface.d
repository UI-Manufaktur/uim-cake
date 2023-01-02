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
     * @param uim.cake.databases.IExpression|array|string $field The field to compare with.
     */
    void setField($field): void;

    /**
     * Returns the field name
     *
     * @return uim.cake.databases.IExpression|array|string
     */
    function getField();
}
