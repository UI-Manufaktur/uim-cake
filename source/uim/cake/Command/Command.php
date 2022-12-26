

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.6.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Command;

import uim.cake.consoles.Arguments;
import uim.cake.consoles.BaseCommand;
import uim.cake.consoles.ConsoleIo;
import uim.cake.Datasource\ModelAwareTrait;
import uim.cake.Log\LogTrait;
import uim.cake.ORM\Locator\LocatorAwareTrait;

/**
 * Base class for commands using the full stack
 * CakePHP Framework.
 *
 * Includes traits that integrate logging
 * and ORM models to console commands.
 */
#[\AllowDynamicProperties]
class Command : BaseCommand
{
    use LocatorAwareTrait;
    use LogTrait;
    use ModelAwareTrait;

    /**
     * Constructor
     *
     * By default CakePHP will construct command objects when
     * building the CommandCollection for your application.
     */
    public this()
    {
        this.modelFactory("Table", function ($alias) {
            return this.getTableLocator().get($alias);
        });

        if (this.defaultTable != null) {
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
    function execute(Arguments $args, ConsoleIo $io)
    {
    }
}

// phpcs:disable
class_alias(
    "Cake\Command\Command",
    "Cake\Console\Command"
);
// phpcs:enable
