module uim.cakemmand;

import uim.cake.console.Arguments;
import uim.cake.console.BaseCommand;
import uim.cake.console.consoleIo;
import uim.cake.datasources\ModelAwareTrait;
import uim.cakegs\LogTrait;
import uim.cakem.Locator\LocatorAwareTrait;

/**
 * Base class for commands using the full stack
 * CakePHP Framework.
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
   * By default CakePHP will construct command objects when
   * building the CommandCollection for your application.
   */
  this() {
    this.modelFactory("Table", function (myAlias) {
        return this.getTableLocator().get(myAlias);
    });

    if (this.defaultTable !== null) {
        this.modelClass = this.defaultTable;
    }
    if (isset(this.modelClass)) {
        this.loadModel();
    }
  }

  /**
   * Implement this method with your command"s logic.
   *
   * @param \Cake\Console\Arguments $args The command arguments.
   * @param \Cake\Console\ConsoleIo $io The console io
   * @return int|null|void The exit code or null for success
   */
  auto execute(Arguments $args, ConsoleIo $io)
  {
  }
}
