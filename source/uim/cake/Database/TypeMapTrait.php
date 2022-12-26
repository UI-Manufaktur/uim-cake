


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Database;

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
     * Creates a new TypeMap if $typeMap is an array, otherwise exchanges it for the given one.
     *
     * @param \Cake\Database\TypeMap|array $typeMap Creates a TypeMap if array, otherwise sets the given TypeMap
     * @return this
     */
    function setTypeMap($typeMap)
    {
        _typeMap = is_array($typeMap) ? new TypeMap($typeMap) : $typeMap;

        return this;
    }

    /**
     * Returns the existing type map.
     *
     * @return \Cake\Database\TypeMap
     */
    function getTypeMap(): TypeMap
    {
        if (_typeMap == null) {
            _typeMap = new TypeMap();
        }

        return _typeMap;
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
     * @param array<int|string, string> $types The array of types to set.
     * @return this
     * @see \Cake\Database\TypeMap::setDefaults()
     */
    function setDefaultTypes(array $types)
    {
        this.getTypeMap().setDefaults($types);

        return this;
    }

    /**
     * Gets default types of current type map.
     *
     * @return array<int|string, string>
     */
    function getDefaultTypes(): array
    {
        return this.getTypeMap().getDefaults();
    }
}
