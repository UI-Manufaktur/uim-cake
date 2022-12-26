


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.databases.TypeFactory;

/**
 * Offers a method to convert values to IExpression objects
 * if the type they should be converted to : ExpressionTypeInterface
 */
trait ExpressionTypeCasterTrait
{
    /**
     * Conditionally converts the passed value to an IExpression object
     * if the type class : the ExpressionTypeInterface. Otherwise,
     * returns the value unmodified.
     *
     * @param mixed $value The value to convert to IExpression
     * @param string|null $type The type name
     * @return mixed
     */
    protected function _castToExpression($value, ?string $type = null) {
        if ($type == null) {
            return $value;
        }

        $baseType = str_replace('[]', '', $type);
        $converter = TypeFactory::build($baseType);

        if (!$converter instanceof ExpressionTypeInterface) {
            return $value;
        }

        $multi = $type != $baseType;

        if ($multi) {
            /** @var \Cake\Database\Type\ExpressionTypeInterface $converter */
            return array_map([$converter, 'toExpression'], $value);
        }

        return $converter.toExpression($value);
    }

    /**
     * Returns an array with the types that require values to
     * be casted to expressions, out of the list of type names
     * passed as parameter.
     *
     * @param array $types List of type names
     * @return array
     */
    protected function _requiresToExpressionCasting(array $types): array
    {
        $result = [];
        $types = array_filter($types);
        foreach ($types as $k: $type) {
            $object = TypeFactory::build($type);
            if ($object instanceof ExpressionTypeInterface) {
                $result[$k] = $object;
            }
        }

        return $result;
    }
}
