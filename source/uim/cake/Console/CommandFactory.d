module uim.cake.console;

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
     * @var \Cake\Core\IContainer|null
     */
    protected myContainer;

    /**
     * Constructor
     *
     * @param \Cake\Core\IContainer|null myContainer The container to use if available.
     */
    this(?IContainer myContainer = null) {
        this.container = myContainer;
    }


    function create(string myClassName) {
        if (this.container && this.container.has(myClassName)) {
            $command = this.container.get(myClassName);
        } else {
            $command = new myClassName();
        }

        if (!($command instanceof ICommand) && !($command instanceof Shell)) {
            /** @psalm-suppress DeprecatedClass */
            $valid = implode('` or `', [Shell::class, ICommand::class]);
            myMessage = sprintf('Class `%s` must be an instance of `%s`.', myClassName, $valid);
            throw new InvalidArgumentException(myMessage);
        }

        return $command;
    }
}
