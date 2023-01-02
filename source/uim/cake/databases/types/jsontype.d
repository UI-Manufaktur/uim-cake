


 *


 * @since         3.3.0
  */module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
use InvalidArgumentException;
use PDO;

/**
 * JSON type converter.
 *
 * Use to convert JSON data between PHP and the database types.
 */
class JsonType : BaseType : BatchCastingInterface
{
    /**
     */
    protected int $_encodingOptions = 0;

    /**
     * Convert a value data into a JSON string
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver $driver The driver instance to convert with.
     * @return string|null
     * @throws \InvalidArgumentException
     */
    function toDatabase($value, IDriver $driver): ?string
    {
        if (is_resource($value)) {
            throw new InvalidArgumentException("Cannot convert a resource value to JSON");
        }

        if ($value == null) {
            return null;
        }

        return json_encode($value, _encodingOptions);
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed $value The value to convert.
     * @param uim.cake.databases.IDriver $driver The driver instance to convert with.
     * @return array|string|null
     */
    function toPHP($value, IDriver $driver) {
        if (!is_string($value)) {
            return null;
        }

        return json_decode($value, true);
    }


    function manyToPHP(array $values, array $fields, IDriver $driver): array
    {
        foreach ($fields as $field) {
            if (!isset($values[$field])) {
                continue;
            }

            $values[$field] = json_decode($values[$field], true);
        }

        return $values;
    }

    /**
     * Get the correct PDO binding type for string data.
     *
     * @param mixed $value The value being bound.
     * @param uim.cake.databases.IDriver $driver The driver.
     */
    int toStatement($value, IDriver $driver): int
    {
        return PDO::PARAM_STR;
    }

    /**
     * Marshals request data into a JSON compatible structure.
     *
     * @param mixed $value The value to convert.
     * @return mixed Converted value.
     */
    function marshal($value) {
        return $value;
    }

    /**
     * Set json_encode options.
     *
     * @param int $options Encoding flags. Use JSON_* flags. Set `0` to reset.
     * @return this
     * @see https://www.php.net/manual/en/function.json-encode.php
     */
    function setEncodingOptions(int $options) {
        _encodingOptions = $options;

        return this;
    }
}