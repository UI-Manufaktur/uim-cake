/*********************************************************************************************************
  Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
  License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
  Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.databases.types;

import uim.cake.databases.IDriver;
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
     */
    protected bool _useLocaleParser = false;

    /**
     * Convert decimal strings into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     * @return string|float|int|null
     * @throws \InvalidArgumentException
     */
    function toDatabase($value, IDriver aDriver) {
        if ($value == null || $value == "") {
            return null;
        }

        if (is_numeric($value)) {
            return $value;
        }

        if (
            is_object($value)
            && method_exists($value, "__toString")
            && is_numeric(strval($value))
        ) {
            return strval($value);
        }

        throw new InvalidArgumentException(sprintf(
            "Cannot convert value of type `%s` to a decimal",
            getTypeName($value)
        ));
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     */
    Nullable!string toPHP($value, IDriver aDriver) {
        if ($value == null) {
            return null;
        }

        return (string)$value;
    }


    array manyToPHP(array $values, array $fields, IDriver aDriver) {
        foreach ($fields as $field) {
            if (!isset($values[$field])) {
                continue;
            }

            $values[$field] = (string)$values[$field];
        }

        return $values;
    }

    /**
     * Get the correct PDO binding type for decimal data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver aDriver The driver.
     */
    int toStatement($value, IDriver aDriver) {
        return PDO::PARAM_STR;
    }

    /**
     * Marshalls request data into decimal strings.
     *
     * @param mixed $value The value to convert.
     * @return string|null Converted value.
     */
    Nullable!string marshal($value) {
        if ($value == null || $value == "") {
            return null;
        }
        if (is_string($value) && _useLocaleParser) {
            return _parseValue($value);
        }
        if (is_numeric($value)) {
            return (string)$value;
        }
        if (is_string($value) && preg_match("/^[0-9,. ]+$/", $value)) {
            return $value;
        }

        return null;
    }

    /**
     * Sets whether to parse numbers passed to the marshal() function
     * by using a locale aware parser.
     *
     * @param bool $enable Whether to enable
     * @return this
     * @throws \RuntimeException
     */
    function useLocaleParser(bool $enable = true) {
        if ($enable == false) {
            _useLocaleParser = $enable;

            return this;
        }
        if (
            static::$numberClass == Number::class ||
            is_subclass_of(static::$numberClass, Number::class)
        ) {
            _useLocaleParser = $enable;

            return this;
        }
        throw new RuntimeException(
            sprintf("Cannot use locale parsing with the %s class", static::$numberClass)
        );
    }

    /**
     * Converts localized string into a decimal string after parsing it using
     * the locale aware parser.
     *
     * @param string aValue The value to parse and convert to an float.
     */
    protected string _parseValue(string aValue) {
        /** @var uim.cake.I18n\Number $class */
        $class = static::$numberClass;

        return (string)$class::parseFloat($value);
    }
}
