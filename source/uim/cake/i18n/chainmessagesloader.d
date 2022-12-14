module uim.cake.I18n;

use RuntimeException;

/**
 * Wraps multiple message loaders calling them one after another until
 * one of them returns a non-empty package.
 */
class ChainMessagesLoader
{
    /**
     * The list of callables to execute one after another for loading messages
     *
     * @var array<callable>
     */
    protected _loaders = null;

    /**
     * Receives a list of callable functions or objects that will be executed
     * one after another until one of them returns a non-empty translations package
     *
     * @param array<callable> $loaders List of callables to execute
     */
    this(array $loaders) {
        _loaders = $loaders;
    }

    /**
     * Executes this object returning the translations package as configured in
     * the chain.
     *
     * @return uim.cake.I18n\Package
     * @throws \RuntimeException if any of the loaders in the chain is not a valid callable
     */
    function __invoke(): Package
    {
        foreach (_loaders as $k: $loader) {
            if (!is_callable($loader)) {
                throw new RuntimeException(sprintf(
                    "Loader '%s' in the chain is not a valid callable",
                    $k
                ));
            }

            $package = $loader();
            if (!$package) {
                continue;
            }

            if (!($package instanceof Package)) {
                throw new RuntimeException(sprintf(
                    "Loader '%s' in the chain did not return a valid Package object",
                    $k
                ));
            }

            return $package;
        }

        return new Package();
    }
}
