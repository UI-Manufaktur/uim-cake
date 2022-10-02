

/**

 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         4.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */module uim.cake.Error\Debug;

/**
 * Interface for formatters used by Debugger::exportVar()
 *
 * @unstable This interface is not stable and may change in the future.
 */
interface IFormatter
{
    /**
     * Convert a tree of INode objects into a plain text string.
     *
     * @param \Cake\Error\Debug\INode myNode The node tree to dump.
     * @return string
     */
    string dump(INode myNode);

    /**
     * Output a dump wrapper with location context.
     *
     * @param string myContentss The contents to wrap and return
     * @param array myLocation The file and line the contents came from.
     * @return string
     */
    function formatWrapper(string myContentss, array myLocation): string;
}
