


 *


 * @since         3.3.4
  */module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
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
     */
    protected bool $_useLocaleParser = false;

    /**
     * Convert decimal strings into the database format.
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return string|float|int|null
     * @throws \InvalidArgumentException
     */
    function toDatabase($value, DriverInterface $driver) {
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
     * @param uim.cake.databases.DriverInterface $driver The driver instance to convert with.
     * @return string|null
     */
    function toPHP($value, DriverInterface $driver): ?string
    {
        if ($value == null) {
            return null;
        }

        return (string)$value;
    }


    function manyToPHP(array $values, array $fields, DriverInterface $driver): array
    {
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
     * @param uim.cake.databases.DriverInterface $driver The driver.
     * @return int
     */
    function toStatement($value, DriverInterface $driver): int
    {
        return PDO::PARAM_STR;
    }

    /**
     * Marshalls request data into decimal strings.
     *
     * @param mixed $value The value to convert.
     * @return string|null Converted value.
     */
    function marshal($value): ?string
    {
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
     * @param string $value The value to parse and convert to an float.
     * @return string
     */
    protected function _parseValue(string $value): string
    {
        /** @var uim.cake.I18n\Number $class */
        $class = static::$numberClass;

        return (string)$class::parseFloat($value);
    }
}
