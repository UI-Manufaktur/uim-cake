


 *


 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Console;

/**
 * An interface for shells that take a CommandCollection
 * during initialization.
 */
interface CommandCollectionAwareInterface
{
    /**
     * Set the command collection being used.
     *
     * @param \Cake\Console\CommandCollection $commands The commands to use.
     * @return void
     */
    function setCommandCollection(CommandCollection $commands): void;
}
