module uim.cake.databases;

import uim.cake.databases.Type\BatchCastingInterface;
import uim.cake.databases.Type\IOptionalConvert;

/**
 * A callable class to be used for processing each of the rows in a statement
 * result, so that the values are converted to the right PHP types.
 */
class FieldTypeConverter
{
    /**
     * An array containing the name of the fields and the Type objects
     * each should use when converting them.
     *
     * @var array<\Cake\Database\TypeInterface>
     */
    protected $_typeMap;

    /**
     * An array containing the name of the fields and the Type objects
     * each should use when converting them using batching.
     *
     * @var array<string, array>
     */
    protected $batchingTypeMap;

    /**
     * An array containing all the types registered in the Type system
     * at the moment this object is created. Used so that the types list
     * is not fetched on each single row of the results.
     *
     * @var array<\Cake\Database\TypeInterface|\Cake\Database\Type\BatchCastingInterface>
     */
    protected myTypes;

    /**
     * The driver object to be used in the type conversion
     *
     * @var \Cake\Database\IDriver
     */
    protected $_driver;

    /**
     * Builds the type map
     *
     * @param \Cake\Database\TypeMap myTypeMap Contains the types to use for converting results
     * @param \Cake\Database\IDriver myDriver The driver to use for the type conversion
     */
    this(TypeMap myTypeMap, IDriver myDriver) {
        this._driver = myDriver;
        $map = myTypeMap.toArray();
        myTypes = TypeFactory::buildAll();

        $simpleMap = $batchingMap = [];
        $simpleResult = $batchingResult = [];

        foreach (myTypes as $k => myType) {
            if (myType instanceof IOptionalConvert && !myType.requiresToPhpCast()) {
                continue;
            }

            if (myType instanceof BatchCastingInterface) {
                $batchingMap[$k] = myType;
                continue;
            }

            $simpleMap[$k] = myType;
        }

        foreach ($map as myField => myType) {
            if (isset($simpleMap[myType])) {
                $simpleResult[myField] = $simpleMap[myType];
                continue;
            }
            if (isset($batchingMap[myType])) {
                $batchingResult[myType][] = myField;
            }
        }

        // Using batching when there is only a couple for the type is actually slower,
        // so, let"s check for that case here.
        foreach ($batchingResult as myType => myFields) {
            if (count(myFields) > 2) {
                continue;
            }

            foreach (myFields as $f) {
                $simpleResult[$f] = $batchingMap[myType];
            }
            unset($batchingResult[myType]);
        }

        this.types = myTypes;
        this._typeMap = $simpleResult;
        this.batchingTypeMap = $batchingResult;
    }

    /**
     * Converts each of the fields in the array that are present in the type map
     * using the corresponding Type class.
     *
     * @param array $row The array with the fields to be casted
     * @return array
     */
    auto __invoke(array $row): array
    {
        if (!empty(this._typeMap)) {
            foreach (this._typeMap as myField => myType) {
                $row[myField] = myType.toPHP($row[myField], this._driver);
            }
        }

        if (!empty(this.batchingTypeMap)) {
            foreach (this.batchingTypeMap as $t => myFields) {
                /** @psalm-suppress PossiblyUndefinedMethod */
                $row = this.types[$t].manyToPHP($row, myFields, this._driver);
            }
        }

        return $row;
    }
}
