module uim.cake.databases.Type;

/**
 * An interface used by Type objects to signal whether the casting
 * is actually required.
 */
interface OptionalConvertInterface
{
    /**
     * Returns whether the cast to PHP is required to be invoked, since
     * it is not a identity function.
     *
     */
    bool requiresToPhpCast(): bool;
}
