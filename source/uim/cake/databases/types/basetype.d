module uim.cake.databases.types;

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
     */
    protected Nullable!string _name;

    /**
     * Constructor
     *
     * @param string|null $name The name identifying this type
     */
    this(Nullable!string aName = null) {
        _name = $name;
    }


    Nullable!string getName() {
        return _name;
    }


    Nullable!string getBaseType() {
        return _name;
    }


    function toStatement($value, IDriver aDriver) {
        if ($value == null) {
            return PDO::PARAM_NULL;
        }

        return PDO::PARAM_STR;
    }


    function newId() {
        return null;
    }
}
