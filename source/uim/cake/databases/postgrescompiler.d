/*********************************************************************************************************
	Copyright: © 2015-2023 Ozan Nurettin Süel (Sicherheitsschmiede)                                        
	License: Subject to the terms of the Apache 2.0 license, as written in the included LICENSE.txt file.  
	Authors: Ozan Nurettin Süel (Sicherheitsschmiede)                                                      
**********************************************************************************************************/module uim.cake.databases.postgrescompiler;

@safe:
import uim.cake;

module uim.cake.databases;

import uim.cake.databases.expressions.FunctionExpression;

/**
 * Responsible for compiling a Query object into its SQL representation
 * for Postgres
 *
 * @internal
 */
class PostgresCompiler : QueryCompiler
{
    /**
     * Always quote aliases in SELECT clause.
     *
     * Postgres auto converts unquoted identifiers to lower case.
     *
     */
    protected bool $_quotedSelectAliases = true;


    protected $_templates = [
        "delete": "DELETE",
        "where": " WHERE %s",
        "group": " GROUP BY %s",
        "order": " %s",
        "limit": " LIMIT %s",
        "offset": " OFFSET %s",
        "epilog": " %s",
    ];

    /**
     * Helper function used to build the string representation of a HAVING clause,
     * it constructs the field list taking care of aliasing and
     * converting expression objects to string.
     *
     * @param array $parts list of fields to be transformed to string
     * @param uim.cake.databases.Query $query The query that is being compiled
     * @param uim.cake.databases.ValueBinder aBinder Value binder used to generate parameter placeholder
     */
    protected string _buildHavingPart($parts, $query, $binder) {
        $selectParts = $query.clause("select");

        foreach ($selectParts as $selectKey: $selectPart) {
            if (!$selectPart instanceof FunctionExpression) {
                continue;
            }
            foreach ($parts as $k: $p) {
                if (!is_string($p)) {
                    continue;
                }
                preg_match_all(
                    "/\b" ~ trim($selectKey, """) ~ "\b/i",
                    $p,
                    $matches
                );

                if (empty($matches[0])) {
                    continue;
                }

                $parts[$k] = preg_replace(
                    ["/"/", "/\b" ~ trim($selectKey, """) ~ "\b/i"],
                    ["", $selectPart.sql($binder)],
                    $p
                );
            }
        }

        return sprintf(" HAVING %s", implode(", ", $parts));
    }
}
