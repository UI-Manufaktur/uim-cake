

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.4
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.database.Type;

import uim.cake.database.IDriver;
import uim.cake.I18n\Number;
use InvalidArgumentException;
use PDO;
use RuntimeException;

/**
 * Decimal type converter.
 *
 * Use to convert decimal data between PHP and the database types.
 */
class DecimalType : BaseType : BatchCastingInterface
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
     * Convert decimal strings into the database format.
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return string|float|int|null
     * @throws \InvalidArgumentException
     */
    function toDatabase(myValue, IDriver myDriver)
    {
        if (myValue === null || myValue === '') {
            return null;
        }

        if (is_numeric(myValue)) {
            return myValue;
        }

        if (
            is_object(myValue)
            && method_exists(myValue, '__toString')
            && is_numeric(strval(myValue))
        ) {
            return strval(myValue);
        }

        throw new InvalidArgumentException(sprintf(
            'Cannot convert value of type `%s` to a decimal',
            getTypeName(myValue)
        ));
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return string|null
     */
    string toPHP(myValue, IDriver myDriver)
    {
        if (myValue === null) {
            return null;
        }

        return (string)myValue;
    }


    function manyToPHP(array myValues, array myFields, IDriver myDriver): array
    {
        foreach (myFields as myField) {
            if (!isset(myValues[myField])) {
                continue;
            }

            myValues[myField] = (string)myValues[myField];
        }

        return myValues;
    }

    /**
     * Get the correct PDO binding type for decimal data.
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
     * Marshalls request data into decimal strings.
     *
     * @param mixed myValue The value to convert.
     * @return string|null Converted value.
     */
    string marshal(myValue)
    {
        if (myValue === null || myValue === '') {
            return null;
        }
        if (is_string(myValue) && this._useLocaleParser) {
            return this._parseValue(myValue);
        }
        if (is_numeric(myValue)) {
            return (string)myValue;
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
     * @throws \RuntimeException
     */
    function useLocaleParser(bool myEnable = true)
    {
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
     * Converts localized string into a decimal string after parsing it using
     * the locale aware parser.
     *
     * @param string myValue The value to parse and convert to an float.
     * @return string
     */
    protected auto _parseValue(string myValue): string
    {
        /** @var \Cake\I18n\Number myClass */
        myClass = static::$numberClass;

        return (string)myClass::parseFloat(myValue);
    }
}
