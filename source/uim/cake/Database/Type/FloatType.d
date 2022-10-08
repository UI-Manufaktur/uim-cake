module uim.cake.database.Type;

import uim.cake.database.IDriver;
import uim.cake.I18n\Number;
use PDO;
use RuntimeException;

/**
 * Float type converter.
 *
 * Use to convert float/decimal data between PHP and the database types.
 */
class FloatType : BaseType : BatchCastingInterface
{
    /**
     * The class to use for representing number objects
     *
     * @var string
     */
    static $numberClass = Number::class;

    /**
     * Whether numbers should be parsed using a locale aware parser
     * when marshalling string inputs.
     *
     * @var bool
     */
    protected $_useLocaleParser = false;

    /**
     * Convert integer data into the database format.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return float|null
     */
    function toDatabase(myValue, IDriver myDriver): ?float
    {
        if (myValue === null || myValue === '') {
            return null;
        }

        return (float)myValue;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return float|null
     * @throws \Cake\Core\Exception\CakeException
     */
    function toPHP(myValue, IDriver myDriver): ?float
    {
        if (myValue === null) {
            return null;
        }

        return (float)myValue;
    }


    function manyToPHP(array myValues, array myFields, IDriver myDriver): array
    {
        foreach (myFields as myField) {
            if (!isset(myValues[myField])) {
                continue;
            }

            myValues[myField] = (float)myValues[myField];
        }

        return myValues;
    }

    /**
     * Get the correct PDO binding type for float data.
     *
     * @param mixed myValue The value being bound.
     * @param \Cake\Database\IDriver myDriver The driver.
     * @return int
     */
    function toStatement(myValue, IDriver myDriver): int
    {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into PHP floats.
     *
     * @param mixed myValue The value to convert.
     * @return string|float|null Converted value.
     */
    function marshal(myValue) {
        if (myValue === null || myValue === '') {
            return null;
        }
        if (is_string(myValue) && this._useLocaleParser) {
            return this._parseValue(myValue);
        }
        if (is_numeric(myValue)) {
            return (float)myValue;
        }
        if (is_string(myValue) && preg_match('/^[0-9,. ]+$/', myValue)) {
            return myValue;
        }

        return null;
    }

    /**
     * Sets whether to parse numbers passed to the marshal() function
     * by using a locale aware parser.
     *
     * @param bool myEnable Whether to enable
     * @return this
     */
    function useLocaleParser(bool myEnable = true) {
        if (myEnable === false) {
            this._useLocaleParser = myEnable;

            return this;
        }
        if (
            static::$numberClass === Number::class ||
            is_subclass_of(static::$numberClass, Number::class)
        ) {
            this._useLocaleParser = myEnable;

            return this;
        }
        throw new RuntimeException(
            sprintf('Cannot use locale parsing with the %s class', static::$numberClass)
        );
    }

    /**
     * Converts a string into a float point after parsing it using the locale
     * aware parser.
     *
     * @param string myValue The value to parse and convert to an float.
     * @return float
     */
    protected auto _parseValue(string myValue): float
    {
        myClass = static::$numberClass;

        return myClass::parseFloat(myValue);
    }
}
