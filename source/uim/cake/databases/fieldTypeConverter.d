module uim.cake.databases;

@safe:
import uim.cake;

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
     * @var array<uim.cake.databases.IType>
     */
    protected _typeMap;

    /**
     * An array containing the name of the fields and the Type objects
     * each should use when converting them using batching.
     *
     * @var array<string, array>
     */
    protected batchingTypeMap;

    /**
     * An array containing all the types registered in the Type system
     * at the moment this object is created. Used so that the types list
     * is not fetched on each single row of the results.
     *
     * @var array<uim.cake.databases.IType|uim.cake.databases.Type\BatchCastingInterface>
     */
    protected myTypes;

    /**
     * The driver object to be used in the type conversion
     *
     * @var uim.cake.databases.IDriver
     */
    protected _driver;

    /**
     * Builds the type map
     *
     * @param uim.cake.databases.TypeMap myTypeMap Contains the types to use for converting results
     * @param uim.cake.databases.IDriver myDriver The driver to use for the type conversion
     */
    this(TypeMap myTypeMap, IDriver myDriver) {
        _driver = myDriver;
        $map = myTypeMap.toArray();
        myTypes = TypeFactory::buildAll();

        $simpleMap = $batchingMap = [];
        $simpleResult = $batchingResult = [];

        foreach (myTypes as $k: myType) {
            if (myType instanceof IOptionalConvert && !myType.requiresToPhpCast()) {
                continue;
            }

            if (myType instanceof BatchCastingInterface) {
                $batchingMap[$k] = myType;
                continue;
            }

            $simpleMap[$k] = myType;
        }

        foreach ($map as myField: myType) {
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
        foreach ($batchingResult as myType: myFields) {
            if (count(myFields) > 2) {
                continue;
            }

            foreach (myFields as $f) {
                $simpleResult[$f] = $batchingMap[myType];
            }
            unset($batchingResult[myType]);
        }

        this.types = myTypes;
        _typeMap = $simpleResult;
        this.batchingTypeMap = $batchingResult;
    }

    /**
     * Converts each of the fields in the array that are present in the type map
     * using the corresponding Type class.
     *
     * @param array $row The array with the fields to be casted
     */
    array __invoke(array $row) {
        if (!empty(_typeMap)) {
            foreach (_typeMap as myField: myType) {
                $row[myField] = myType.toPHP($row[myField], _driver);
            }
        }

        if (!empty(this.batchingTypeMap)) {
            foreach (this.batchingTypeMap as $t: myFields) {
                /** @psalm-suppress PossiblyUndefinedMethod */
                $row = this.types[$t].manyToPHP($row, myFields, _driver);
            }
        }

        return $row;
    }
}
