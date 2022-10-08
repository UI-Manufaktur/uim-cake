module uim.cake.database;

/*
 * Represents a class that holds a TypeMap object
 */
/**
 * Trait TypeMapTrait
 */
trait TypeMapTrait
{
    /**
     * @var \Cake\Database\TypeMap|null
     */
    protected $_typeMap;

    /**
     * Creates a new TypeMap if myTypeMap is an array, otherwise exchanges it for the given one.
     *
     * @param \Cake\Database\TypeMap|array myTypeMap Creates a TypeMap if array, otherwise sets the given TypeMap
     * @return this
     */
    auto setTypeMap(myTypeMap) {
        this._typeMap = is_array(myTypeMap) ? new TypeMap(myTypeMap) : myTypeMap;

        return this;
    }

    /**
     * Returns the existing type map.
     *
     * @return \Cake\Database\TypeMap
     */
    auto getTypeMap(): TypeMap
    {
        if (this._typeMap === null) {
            this._typeMap = new TypeMap();
        }

        return this._typeMap;
    }

    /**
     * Overwrite the default type mappings for fields
     * in the implementing object.
     *
     * This method is useful if you need to set type mappings that are shared across
     * multiple functions/expressions in a query.
     *
     * To add a default without overwriting existing ones
     * use `getTypeMap().addDefaults()`
     *
     * @param array<string, string> myTypes The array of types to set.
     * @return this
     * @see \Cake\Database\TypeMap::setDefaults()
     */
    auto setDefaultTypes(array myTypes) {
        this.getTypeMap().setDefaults(myTypes);

        return this;
    }

    /**
     * Gets default types of current type map.
     *
     * @return array<string, string>
     */
    auto getDefaultTypes(): array
    {
        return this.getTypeMap().getDefaults();
    }
}
