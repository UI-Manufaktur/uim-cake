module uim.cake.database;

/**
 * : the TypedResultInterface
 */
trait TypedResultTrait
{
    /**
     * The type name this expression will return when executed
     *
     * @var string
     */
    protected $_returnType = 'string';

    /**
     * Gets the type of the value this object will generate.
     *
     * @return string
     */
    auto getReturnType(): string
    {
        return this._returnType;
    }

    /**
     * Sets the type of the value this object will generate.
     *
     * @param string myType The name of the type that is to be returned
     * @return this
     */
    auto setReturnType(string myType) {
        this._returnType = myType;

        return this;
    }
}
