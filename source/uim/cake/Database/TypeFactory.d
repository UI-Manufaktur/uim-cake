module uim.cake.databases;

use InvalidArgumentException;

/**
 * Factory for building database type classes.
 */
class TypeFactory
{
    /**
     * List of supported database types. A human readable
     * identifier is used as key and a complete namespaced class name as value
     * representing the class that will do actual type conversions.
     *
     * @var array<string, string>
     * @psalm-var array<string, class-string<uim.cake.databases.TypeInterface>>
     */
    protected static $_types = [
        "tinyinteger": Type\IntegerType::class,
        "smallinteger": Type\IntegerType::class,
        "integer": Type\IntegerType::class,
        "biginteger": Type\IntegerType::class,
        "binary": Type\BinaryType::class,
        "binaryuuid": Type\BinaryUuidType::class,
        "boolean": Type\BoolType::class,
        "date": Type\DateType::class,
        "datetime": Type\DateTimeType::class,
        "datetimefractional": Type\DateTimeFractionalType::class,
        "decimal": Type\DecimalType::class,
        "float": Type\FloatType::class,
        "json": Type\JsonType::class,
        "string": Type\StringType::class,
        "char": Type\StringType::class,
        "text": Type\StringType::class,
        "time": Type\TimeType::class,
        "timestamp": Type\DateTimeType::class,
        "timestampfractional": Type\DateTimeFractionalType::class,
        "timestamptimezone": Type\DateTimeTimezoneType::class,
        "uuid": Type\UuidType::class,
    ];

    /**
     * Contains a map of type object instances to be reused if needed.
     *
     * @var array<uim.cake.databases.TypeInterface>
     */
    protected static $_builtTypes = [];

    /**
     * Returns a Type object capable of converting a type identified by name.
     *
     * @param string aName type identifier
     * @throws \InvalidArgumentException If type identifier is unknown
     * @return uim.cake.databases.TypeInterface
     */
    static function build(string aName): TypeInterface
    {
        if (isset(static::$_builtTypes[$name])) {
            return static::$_builtTypes[$name];
        }
        if (!isset(static::$_types[$name])) {
            throw new InvalidArgumentException(sprintf("Unknown type "%s"", $name));
        }

        return static::$_builtTypes[$name] = new static::$_types[$name]($name);
    }

    /**
     * Returns an arrays with all the mapped type objects, indexed by name.
     *
     * @return array<uim.cake.databases.TypeInterface>
     */
    static function buildAll(): array
    {
        $result = [];
        foreach (static::$_types as $name: $type) {
            $result[$name] = static::$_builtTypes[$name] ?? static::build($name);
        }

        return $result;
    }

    /**
     * Set TypeInterface instance capable of converting a type identified by $name
     *
     * @param string aName The type identifier you want to set.
     * @param uim.cake.databases.TypeInterface $instance The type instance you want to set.
     */
    static void set(string aName, TypeInterface $instance) {
        static::$_builtTypes[$name] = $instance;
        static::$_types[$name] = get_class($instance);
    }

    /**
     * Registers a new type identifier and maps it to a fully namespaced classname.
     *
     * @param string $type Name of type to map.
     * @param string $className The classname to register.
     * @return void
     * @psalm-param class-string<uim.cake.databases.TypeInterface> $className
     */
    static void map(string $type, string $className) {
        static::$_types[$type] = $className;
        unset(static::$_builtTypes[$type]);
    }

    /**
     * Set type to classname mapping.
     *
     * @param array<string> $map List of types to be mapped.
     * @return void
     * @psalm-param array<string, class-string<uim.cake.databases.TypeInterface>> $map
     */
    static void setMap(array $map) {
        static::$_types = $map;
        static::$_builtTypes = [];
    }

    /**
     * Get mapped class name for given type or map array.
     *
     * @param string|null $type Type name to get mapped class for or null to get map array.
     * @return array<string>|string|null Configured class name for given $type or map array.
     */
    static function getMap(?string $type = null) {
        if ($type == null) {
            return static::$_types;
        }

        return static::$_types[$type] ?? null;
    }

    /**
     * Clears out all created instances and mapped types classes, useful for testing
     *
     */
    static void clear() {
        static::$_types = [];
        static::$_builtTypes = [];
    }
}
