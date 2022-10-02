

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.3.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.database.Type;

import uim.cake.database.IDriver;
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
     * @var int
     */
    protected $_encodingOptions = 0;

    /**
     * Convert a value data into a JSON string
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return string|null
     * @throws \InvalidArgumentException
     */
    function toDatabase(myValue, IDriver myDriver): ?string
    {
        if (is_resource(myValue)) {
            throw new InvalidArgumentException('Cannot convert a resource value to JSON');
        }

        if (myValue === null) {
            return null;
        }

        return json_encode(myValue, this._encodingOptions);
    }

    /**
     * {@inheritDoc}
     *
     * @param mixed myValue The value to convert.
     * @param \Cake\Database\IDriver myDriver The driver instance to convert with.
     * @return array|string|null
     */
    function toPHP(myValue, IDriver myDriver)
    {
        if (!is_string(myValue)) {
            return null;
        }

        return json_decode(myValue, true);
    }

    /**
     * @inheritDoc
     */
    function manyToPHP(array myValues, array myFields, IDriver myDriver): array
    {
        foreach (myFields as myField) {
            if (!isset(myValues[myField])) {
                continue;
            }

            myValues[myField] = json_decode(myValues[myField], true);
        }

        return myValues;
    }

    /**
     * Get the correct PDO binding type for string data.
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
     * Marshals request data into a JSON compatible structure.
     *
     * @param mixed myValue The value to convert.
     * @return mixed Converted value.
     */
    function marshal(myValue)
    {
        return myValue;
    }

    /**
     * Set json_encode options.
     *
     * @param int myOptions Encoding flags. Use JSON_* flags. Set `0` to reset.
     * @return this
     * @see https://www.php.net/manual/en/function.json-encode.php
     */
    auto setEncodingOptions(int myOptions)
    {
        this._encodingOptions = myOptions;

        return this;
    }
}
