module uim.cake.databases;

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
     * @param mixed $value The value to cast
     * @param uim.cake.databases.TypeInterface|string|int $type The type name or type instance to use.
     * @return array list containing converted value and internal type
     * @pslam-return array{mixed, int}
     */
    function cast($value, $type = "string"): array
    {
        if (is_string($type)) {
            $type = TypeFactory::build($type);
        }
        if ($type instanceof TypeInterface) {
            $value = $type.toDatabase($value, _driver);
            $type = $type.toStatement($value, _driver);
        }

        return [$value, $type];
    }

    /**
     * Matches columns to corresponding types
     *
     * Both $columns and $types should either be numeric based or string key based at
     * the same time.
     *
     * @param array $columns list or associative array of columns and parameters to be bound with types
     * @param array $types list or associative array of types
     */
    array matchTypes(array $columns, array $types): array
    {
        if (!is_int(key($types))) {
            $positions = array_intersect_key(array_flip($columns), $types);
            $types = array_intersect_key($types, $positions);
            $types = array_combine($positions, $types);
        }

        return $types;
    }
}
