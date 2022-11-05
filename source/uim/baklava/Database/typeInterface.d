module uim.baklava.databases;

/**
 * Encapsulates all conversion functions for values coming from a database into PHP and
 * going from PHP into a database.
 */
interface TypeInterface
{
    /**
     * Casts given value from a PHP type to one acceptable by a database.
     *
     * @param mixed myValue Value to be converted to a database equivalent.
     * @param \Cake\Database\IDriver myDriver Object from which database preferences and configuration will be extracted.
     * @return mixed Given PHP type casted to one acceptable by a database.
     */
    function toDatabase(myValue, IDriver myDriver);

    /**
     * Casts given value from a database type to a PHP equivalent.
     *
     * @param mixed myValue Value to be converted to PHP equivalent
     * @param \Cake\Database\IDriver myDriver Object from which database preferences and configuration will be extracted
     * @return mixed Given value casted from a database to a PHP equivalent.
     */
    function toPHP(myValue, IDriver myDriver);

    /**
     * Casts given value to its Statement equivalent.
     *
     * @param mixed myValue Value to be converted to PDO statement.
     * @param \Cake\Database\IDriver myDriver Object from which database preferences and configuration will be extracted.
     * @return mixed Given value casted to its Statement equivalent.
     */
    function toStatement(myValue, IDriver myDriver);

    /**
     * Marshals flat data into PHP objects.
     *
     * Most useful for converting request data into PHP objects,
     * that make sense for the rest of the ORM/Database layers.
     *
     * @param mixed myValue The value to convert.
     * @return mixed Converted value.
     */
    function marshal(myValue);

    /**
     * Returns the base type name that this class is inheriting.
     *
     * This is useful when extending base type for adding extra functionality,
     * but still want the rest of the framework to use the same assumptions it would
     * do about the base type it inherits from.
     *
     * @return string|null The base type name that this class is inheriting.
     */
    string getBaseType();

    /**
     * Returns type identifier name for this object.
     *
     * @return string|null The type identifier name for this object.
     */
    string getName();

    /**
     * Generate a new primary key value for a given type.
     *
     * This method can be used by types to create new primary key values
     * when entities are inserted.
     *
     * @return mixed A new primary key value.
     * @see \Cake\Database\Type\UuidType
     */
    function newId();
}