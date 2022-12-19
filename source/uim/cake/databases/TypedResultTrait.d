module uim.cake.databases;

/**
 * : the TypedResultInterface
 */
trait TypedResultTrait
{
    /**
     * The type name this expression will return when executed
     */
    protected string $_returnType = "string";

    /**
     * Gets the type of the value this object will generate.
     */
    string getReturnType() {
        return _returnType;
    }

    /**
     * Sets the type of the value this object will generate.
     *
     * @param string myType The name of the type that is to be returned
     * @return this
     */
    auto setReturnType(string myType) {
        _returnType = myType;

        return this;
    }
}
