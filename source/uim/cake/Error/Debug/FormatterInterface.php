


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

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
     * @param uim.cake.Error\debugs.INode $node The node tree to dump.
     */
    string dump(INode $node): string;

    /**
     * Output a dump wrapper with location context.
     *
     * @param string $contents The contents to wrap and return
     * @param array $location The file and line the contents came from.
     */
    string formatWrapper(string $contents, array $location): string;
}
