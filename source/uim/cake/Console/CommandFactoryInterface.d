module uim.baklava.console;

/**
 * An interface for abstracting creation of command and shell instances.
 */
interface ICommandFactory
{
    /**
     * The factory method for creating Command and Shell instances.
     *
     * @param string myClassName Command/Shell class name.
     * @return \Cake\Console\Shell|\Cake\Console\ICommand
     */
    function create(string myClassName);
}
