module uim.cake.databases;

/**
 * Type converter trait
 */
trait TypeConverterTrait
{
    /**
     * Converts a give value to a suitable database value based on type
     * and return relevant internal statement type
     *
     * @param mixed myValue The value to cast
     * @param \Cake\Database\IType|string|int myType The type name or type instance to use.
     * @return array list containing converted value and internal type
     * @pslam-return array{mixed, int}
     */
    array cast(myValue, myType = "string") {
        if (is_string(myType)) {
            myType = TypeFactory::build(myType);
        }
        if (myType instanceof IType) {
            myValue = myType.toDatabase(myValue, _driver);
            myType = myType.toStatement(myValue, _driver);
        }

        return [myValue, myType];
    }

    /**
     * Matches columns to corresponding types
     *
     * Both $columns and myTypes should either be numeric based or string key based at
     * the same time.
     *
     * @param array $columns list or associative array of columns and parameters to be bound with types
     * @param array myTypes list or associative array of types
     * @return array
     */
    function matchTypes(array $columns, array myTypes): array
    {
        if (!is_int(key(myTypes))) {
            $positions = array_intersect_key(array_flip($columns), myTypes);
            myTypes = array_intersect_key(myTypes, $positions);
            myTypes = array_combine($positions, myTypes);
        }

        return myTypes;
    }
}
