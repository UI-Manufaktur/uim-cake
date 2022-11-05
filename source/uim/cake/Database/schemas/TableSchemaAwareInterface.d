module uim.baklava.databases.Schema;

/**
 * Defines the interface for getting the schema.
 */
interface TableSchemaAwareInterface
{
    /**
     * Get and set the schema for this fixture.
     *
     * @return \Cake\Database\Schema\TableSchemaInterface&\Cake\Database\Schema\ISqlGenerator
     */
    auto getTableSchema();

    /**
     * Get and set the schema for this fixture.
     *
     * @param \Cake\Database\Schema\TableSchemaInterface&\Cake\Database\Schema\ISqlGenerator $schema The table to set.
     * @return this
     */
    auto setTableSchema($schema);
}
