

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.databases.Type;

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
     * @param mixed myValue The value to convert to IExpression
     * @param string|null myType The type name
     * @return mixed
     */
    protected auto _castToExpression(myValue, ?string myType = null) {
        if (myType === null) {
            return myValue;
        }

        $baseType = str_replace('[]', '', myType);
        $converter = TypeFactory::build($baseType);

        if (!$converter instanceof ExpressionTypeInterface) {
            return myValue;
        }

        $multi = myType !== $baseType;

        if ($multi) {
            /** @var \Cake\Database\Type\ExpressionTypeInterface $converter */
            return array_map([$converter, 'toExpression'], myValue);
        }

        return $converter.toExpression(myValue);
    }

    /**
     * Returns an array with the types that require values to
     * be casted to expressions, out of the list of type names
     * passed as parameter.
     *
     * @param array myTypes List of type names
     * @return array
     */
    protected auto _requiresToExpressionCasting(array myTypes): array
    {
        myResult = [];
        myTypes = array_filter(myTypes);
        foreach (myTypes as $k => myType) {
            $object = TypeFactory::build(myType);
            if ($object instanceof ExpressionTypeInterface) {
                myResult[$k] = $object;
            }
        }

        return myResult;
    }
}
