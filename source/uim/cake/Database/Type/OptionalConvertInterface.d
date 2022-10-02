module uim.cake.database.Type;

/**
 * An interface used by Type objects to signal whether the casting
 * is actually required.
 */
interface IOptionalConvert {
    /**
     * Returns whether the cast to PHP is required to be invoked, since
     * it is not a identity function.
     *
     * @return bool
     */
    bool requiresToPhpCast();
}
