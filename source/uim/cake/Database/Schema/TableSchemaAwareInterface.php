
module uim.cake.databases.Schema;

/**
 * Defines the interface for getting the schema.
 */
interface TableSchemaAwareInterface
{
    /**
     * Get and set the schema for this fixture.
     *
     * @return uim.cake.databases.Schema\TableSchemaInterface&uim.cake.databases.Schema\SqlGeneratorInterface
     */
    function getTableSchema();

    /**
     * Get and set the schema for this fixture.
     *
     * @param uim.cake.databases.Schema\TableSchemaInterface&uim.cake.databases.Schema\SqlGeneratorInterface $schema The table to set.
     * @return this
     */
    function setTableSchema($schema);
}
