module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
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
     */
    protected bool _useLocaleParser = false;

    /**
     * Convert integer data into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     * @return float|null
     */
    function toDatabase($value, IDriver aDriver): ?float
    {
        if ($value == null || $value == "") {
            return null;
        }

        return (float)$value;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver aDriver The driver instance to convert with.
     * @return float|null
     * @throws uim.cake.Core\exceptions.CakeException
     */
    function toPHP($value, IDriver aDriver): ?float
    {
        if ($value == null) {
            return null;
        }

        return (float)$value;
    }


    array manyToPHP(array $values, array $fields, IDriver aDriver) {
        foreach ($fields as $field) {
            if (!isset($values[$field])) {
                continue;
            }

            $values[$field] = (float)$values[$field];
        }

        return $values;
    }

    /**
     * Get the correct PDO binding type for float data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver aDriver The driver.
     */
    int toStatement($value, IDriver aDriver) {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into PHP floats.
     *
     * @param mixed $value The value to convert.
     * @return string|float|null Converted value.
     */
    function marshal($value) {
        if ($value == null || $value == "") {
            return null;
        }
        if (is_string($value) && _useLocaleParser) {
            return _parseValue($value);
        }
        if (is_numeric($value)) {
            return (float)$value;
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
     * Converts a string into a float point after parsing it using the locale
     * aware parser.
     *
     * @param string $value The value to parse and convert to an float.
     * @return float
     */
    protected function _parseValue(string $value): float
    {
        $class = static::$numberClass;

        return $class::parseFloat($value);
    }
}
