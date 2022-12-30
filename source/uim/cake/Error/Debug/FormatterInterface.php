


 *


 * @since         4.1.0
  */module uim.cake.errors.Debug;

/**
 * Interface for formatters used by Debugger::exportVar()
 *
 * @unstable This interface is not stable and may change in the future.
 */
interface FormatterInterface
{
    /**
     * Convert a tree of NodeInterface objects into a plain text string.
     *
     * @param uim.cake.Error\Debug\NodeInterface $node The node tree to dump.
     * @return string
     */
    string dump(NodeInterface $node): string;

    /**
     * Output a dump wrapper with location context.
     *
     * @param string $contents The contents to wrap and return
     * @param array $location The file and line the contents came from.
     * @return string
     */
    string formatWrapper(string $contents, array $location): string;
}
