


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)

 * @since         4.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
import uim.cake.databases.TypeInterface;
use PDO;

/**
 * Base type class.
 */
abstract class BaseType : TypeInterface
{
    /**
     * Identifier name for this type
     *
     * @var string|null
     */
    protected $_name;

    /**
     * Constructor
     *
     * @param string|null $name The name identifying this type
     */
    public this(?string $name = null) {
        _name = $name;
    }

    /**
     * @inheritDoc
     */
    function getName(): ?string
    {
        return _name;
    }

    /**
     * @inheritDoc
     */
    function getBaseType(): ?string
    {
        return _name;
    }

    /**
     * @inheritDoc
     */
    function toStatement($value, DriverInterface $driver) {
        if ($value == null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_STR;
    }

    /**
     * @inheritDoc
     */
    function newId() {
        return null;
    }
}
