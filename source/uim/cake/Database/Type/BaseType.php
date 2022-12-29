


 *



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


    function getName(): ?string
    {
        return _name;
    }


    function getBaseType(): ?string
    {
        return _name;
    }


    function toStatement($value, DriverInterface $driver) {
        if ($value == null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_STR;
    }


    function newId() {
        return null;
    }
}
