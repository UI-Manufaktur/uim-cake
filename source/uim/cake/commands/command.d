module uim.cake.command;

@safe:
import uim.cake;

/**
 * Base class for commands using the full stack
 * UIM Framework.
 *
 * Includes traits that integrate logging
 * and ORM models to console commands.
 */
class Command : BaseCommand {
  use LocatorAwareTrait;
  use LogTrait;
  use ModelAwareTrait;

  /**
   * Constructor
   *
   * By default UIM will construct command objects when
   * building the CommandCollection for your application.
   */
  this() {
    this.modelFactory("Table", function (myAlias) {
        return this.getTableLocator().get(myAlias);
    });

    if (this.defaultTable  !is null) {
        this.modelClass = this.defaultTable;
    }
    if (isset(this.modelClass)) {
        this.loadModel();
    }
  }

  /**
   * Implement this method with your command"s logic.
   *
   * @param uim.cake.consoles.Arguments $args The command arguments.
   * @param uim.cake.consoles.ConsoleIo $io The console io
   * @return int|null|void The exit code or null for success
   */
  auto execute(Arguments $args, ConsoleIo $io)
  {
  }
}
