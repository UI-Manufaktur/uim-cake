module uim.cake.ORM;

import uim.cake.Collection\Collection;
import uim.cake.Collection\ICollection;
import uim.cake.databases.expressions.TupleComparison;
import uim.cake.datasources.EntityInterface;

/**
 * Contains methods that are capable of injecting eagerly loaded associations into
 * entities or lists of entities by using the same syntax as the EagerLoader.
 *
 * @internal
 */
class LazyEagerLoader
{
    /**
     * Loads the specified associations in the passed entity or list of entities
     * by executing extra queries in the database and merging the results in the
     * appropriate properties.
     *
     * The properties for the associations to be loaded will be overwritten on each entity.
     *
     * @param uim.cake.Datasource\EntityInterface|array<uim.cake.Datasource\EntityInterface> $entities a single entity or list of entities
     * @param array $contain A `contain()` compatible array.
     * @see uim.cake.orm.Query::contain()
     * @param uim.cake.orm.Table $source The table to use for fetching the top level entities
     * @return uim.cake.Datasource\EntityInterface|array<uim.cake.Datasource\EntityInterface>
     */
    function loadInto($entities, array $contain, Table $source) {
        $returnSingle = false;

        if ($entities instanceof EntityInterface) {
            $entities = [$entities];
            $returnSingle = true;
        }

        $entities = new Collection($entities);
        $query = _getQuery($entities, $contain, $source);
        $associations = array_keys($query.getContain());

        $entities = _injectResults($entities, $query, $associations, $source);

        return $returnSingle ? array_shift($entities) : $entities;
    }

    /**
     * Builds a query for loading the passed list of entity objects along with the
     * associations specified in $contain.
     *
     * @param uim.cake.Collection\ICollection $objects The original entities
     * @param array $contain The associations to be loaded
     * @param uim.cake.orm.Table $source The table to use for fetching the top level entities
     * @return uim.cake.orm.Query
     */
    protected function _getQuery(ICollection $objects, array $contain, Table $source): Query
    {
        $primaryKey = $source.getPrimaryKey();
        $method = is_string($primaryKey) ? "get" : "extract";

        $keys = $objects.map(function ($entity) use ($primaryKey, $method) {
            return $entity.{$method}($primaryKey);
        });

        $query = $source
            .find()
            .select((array)$primaryKey)
            .where(function ($exp, $q) use ($primaryKey, $keys, $source) {
                /**
                 * @var uim.cake.databases.Expression\QueryExpression $exp
                 * @var uim.cake.orm.Query $q
                 */
                if (is_array($primaryKey) && count($primaryKey) == 1) {
                    $primaryKey = current($primaryKey);
                }

                if (is_string($primaryKey)) {
                    return $exp.in($source.aliasField($primaryKey), $keys.toList());
                }

                $types = array_intersect_key($q.getDefaultTypes(), array_flip($primaryKey));
                $primaryKey = array_map([$source, "aliasField"], $primaryKey);

                return new TupleComparison($primaryKey, $keys.toList(), $types, "IN");
            })
            .enableAutoFields()
            .contain($contain);

        foreach ($query.getEagerLoader().attachableAssociations($source) as $loadable) {
            $config = $loadable.getConfig();
            $config["includeFields"] = true;
            $loadable.setConfig($config);
        }

        return $query;
    }

    /**
     * Returns a map of property names where the association results should be injected
     * in the top level entities.
     *
     * @param uim.cake.orm.Table $source The table having the top level associations
     * @param array<string> $associations The name of the top level associations
     * @return array<string>
     */
    protected function _getPropertyMap(Table $source, array $associations): array
    {
        $map = [];
        $container = $source.associations();
        foreach ($associations as $assoc) {
            /** @psalm-suppress PossiblyNullReference */
            $map[$assoc] = $container.get($assoc).getProperty();
        }

        return $map;
    }

    /**
     * Injects the results of the eager loader query into the original list of
     * entities.
     *
     * @param iterable<uim.cake.Datasource\EntityInterface> $objects The original list of entities
     * @param uim.cake.orm.Query $results The loaded results
     * @param array<string> $associations The top level associations that were loaded
     * @param uim.cake.orm.Table $source The table where the entities came from
     * @return array<uim.cake.Datasource\EntityInterface>
     */
    protected function _injectResults(iterable $objects, $results, array $associations, Table $source): array
    {
        $injected = [];
        $properties = _getPropertyMap($source, $associations);
        $primaryKey = (array)$source.getPrimaryKey();
        $results = $results
            .all()
            .indexBy(function ($e) use ($primaryKey) {
                /** @var uim.cake.datasources.EntityInterface $e */
                return implode(";", $e.extract($primaryKey));
            })
            .toArray();

        foreach ($objects as $k: $object) {
            $key = implode(";", $object.extract($primaryKey));
            if (!isset($results[$key])) {
                $injected[$k] = $object;
                continue;
            }

            /** @var uim.cake.datasources.EntityInterface $loaded */
            $loaded = $results[$key];
            foreach ($associations as $assoc) {
                $property = $properties[$assoc];
                $object.set($property, $loaded.get($property), ["useSetters": false]);
                $object.setDirty($property, false);
            }
            $injected[$k] = $object;
        }

        return $injected;
    }
}
