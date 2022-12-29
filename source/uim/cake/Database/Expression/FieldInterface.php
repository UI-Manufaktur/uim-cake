
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
     * @param uim.cake.Database\IExpression|array|string $field The field to compare with.
     * @return void
     */
    function setField($field): void;

    /**
     * Returns the field name
     *
     * @return uim.cake.Database\IExpression|array|string
     */
    function getField();
}
