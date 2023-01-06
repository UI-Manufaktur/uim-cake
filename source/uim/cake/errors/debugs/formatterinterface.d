/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/
module uim.cake.errors.debugs;

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
     * @param uim.cake.errors.debugs.INode myNode The node tree to dump.
     */
    string dump(INode myNode);

    /**
     * Output a dump wrapper with location context.
     *
     * @param string myContentss The contents to wrap and return
     * @param array myLocation The file and line the contents came from.
     */
    string formatWrapper(string myContentss, array myLocation);
}
