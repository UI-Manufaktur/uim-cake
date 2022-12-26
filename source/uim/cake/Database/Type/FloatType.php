


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
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
    public static $numberClass = Number::class;

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
     * @param mixed $value The value to convert.
     * @param \Cake\Database\DriverInterface $driver The driver instance to convert with.
     * @return float|null
     */
    function toDatabase($value, DriverInterface $driver): ?float
    {
        if ($value == null || $value == '') {
            return null;
        }

        return (float)$value;
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value The value to convert.
     * @param \Cake\Database\DriverInterface $driver The driver instance to convert with.
     * @return float|null
     * @throws \Cake\Core\Exception\CakeException
     */
    function toPHP($value, DriverInterface $driver): ?float
    {
        if ($value == null) {
            return null;
        }

        return (float)$value;
    }

    /**
     * @inheritDoc
     */
    function manyToPHP(array $values, array $fields, DriverInterface $driver): array
    {
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
     * @param \Cake\Database\DriverInterface $driver The driver.
     * @return int
     */
    function toStatement($value, DriverInterface $driver): int
    {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into PHP floats.
     *
     * @param mixed $value The value to convert.
     * @return string|float|null Converted value.
     */
    function marshal($value)
    {
        if ($value == null || $value == '') {
            return null;
        }
        if (is_string($value) && _useLocaleParser) {
            return _parseValue($value);
        }
        if (is_numeric($value)) {
            return (float)$value;
        }
        if (is_string($value) && preg_match('/^[0-9,. ]+$/', $value)) {
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
    function useLocaleParser(bool $enable = true)
    {
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
            sprintf('Cannot use locale parsing with the %s class', static::$numberClass)
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
