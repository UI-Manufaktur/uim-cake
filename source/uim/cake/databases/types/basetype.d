module uim.cake.databases.Type;

import uim.cake.databases.IDriver;
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
    this(?string aName = null) {
        _name = $name;
    }


    Nullable!string getName()
    {
        return _name;
    }


    Nullable!string getBaseType()
    {
        return _name;
    }


    function toStatement($value, IDriver $driver) {
        if ($value == null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_STR;
    }


    function newId() {
        return null;
    }
}
