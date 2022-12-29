


 *


 * @since         3.5.0
 * @license       https://www.opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.databases.Schema;

/**
 * Defines the interface for getting the schema.
 */
interface TableSchemaAwareInterface
{
    /**
     * Get and set the schema for this fixture.
     *
     * @return \Cake\Database\Schema\TableSchemaInterface&\Cake\Database\Schema\SqlGeneratorInterface
     */
    function getTableSchema();

    /**
     * Get and set the schema for this fixture.
     *
     * @param uim.cake.Database\Schema\TableSchemaInterface&\Cake\Database\Schema\SqlGeneratorInterface $schema The table to set.
     * @return this
     */
    function setTableSchema($schema);
}
