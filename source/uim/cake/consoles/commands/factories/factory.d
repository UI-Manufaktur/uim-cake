module uim.cake.consoles;

@safe:
import uim.cake;

use InvalidArgumentException;

/**
 * This is a factory for creating Command and Shell instances.
 *
 * This factory can be replaced or extended if you need to customize building
 * your command and shell objects.
 */
class CommandFactory : ICommandFactory {
  protected IContainer _container;

  /**
    * Constructor
    *
    * aContainer - The container to use if available.
    */
  this(IContainer aContainer = null) {
    _container = aContainer;
  }

  function create(string aClassName) {
    if (_container && _container.has(aClassName)) {
      $command = this.container.get(aClassName);
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
