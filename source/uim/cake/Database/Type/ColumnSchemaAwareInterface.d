
module uim.cake.databases.Type;

import uim.cake.databases.DriverInterface;
import uim.cake.databases.schemas.TableISchema;

interface ColumnSchemaAwareInterface
{
    /**
     * Generate the SQL fragment for a single column in a table.
     *
     * @param uim.cake.databases.Schema\TableISchema $schema The table schema instance the column is in.
     * @param string $column The name of the column.
     * @param uim.cake.databases.DriverInterface $driver The driver instance being used.
     * @return string|null An SQL fragment, or `null` in case the column isn"t processed by this type.
     */
    function getColumnSql(TableISchema $schema, string $column, DriverInterface $driver): ?string;

    /**
     * Convert a SQL column definition to an abstract type definition.
     *
     * @param array $definition The column definition.
     * @param uim.cake.databases.DriverInterface $driver The driver instance being used.
     * @return array<string, mixed>|null Array of column information, or `null` in case the column isn"t processed by this type.
     */
    function convertColumnDefinition(array $definition, DriverInterface $driver): ?array;
}