
module uim.cake.databases.Schema;

/**
 * Defines the interface for getting the schema.
 */
interface TableSchemaAwareInterface
{
    /**
     * Get and set the schema for this fixture.
     *
     * @return uim.cake.Database\Schema\TableSchemaInterface&uim.cake.Database\Schema\SqlGeneratorInterface
     */
    function getTableSchema();

    /**
     * Get and set the schema for this fixture.
     *
     * @param uim.cake.Database\Schema\TableSchemaInterface&uim.cake.Database\Schema\SqlGeneratorInterface $schema The table to set.
     * @return this
     */
    function setTableSchema($schema);
}
