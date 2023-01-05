module uim.cake.Console;

import uim.cake.core.IContainer;
use InvalidArgumentException;

/**
 * This is a factory for creating Command and Shell instances.
 *
 * This factory can be replaced or extended if you need to customize building
 * your command and shell objects.
 */
class CommandFactory : ICommandFactory
{
    /**
     * @var uim.cake.Core\IContainer|null
     */
    protected $container;

    /**
     * Constructor
     *
     * @param uim.cake.Core\IContainer|null $container The container to use if available.
     */
    this(?IContainer $container = null) {
        this.container = $container;
    }

    function create(string $className) {
        if (this.container && this.container.has($className)) {
            $command = this.container.get($className);
        } else {
            $command = new $className();
        }

        if (!($command instanceof ICommand) && !($command instanceof Shell)) {
            /** @psalm-suppress DeprecatedClass */
            $valid = implode("` or `", [Shell::class, ICommand::class]);
            $message = sprintf("Class `%s` must be an instance of `%s`.", $className, $valid);
            throw new InvalidArgumentException($message);
        }

        return $command;
    }
}
