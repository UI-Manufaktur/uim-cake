module uim.cake.orm;

import uim.cake.collections\Collection;
import uim.cake.collections\ICollection;
import uim.cake.databases.expressions\TupleComparison;
import uim.cake.datasources\IEntity;

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
     * @param \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity> $entities a single entity or list of entities
     * @param array $contain A `contain()` compatible array.
     * @see uim.cake.ORM\Query::contain()
     * @param \Cake\ORM\Table $source The table to use for fetching the top level entities
     * @return \Cake\Datasource\IEntity|array<\Cake\Datasource\IEntity>
     */
    function loadInto($entities, array $contain, Table $source) {
        $returnSingle = false;

        if ($entities instanceof IEntity) {
            $entities = [$entities];
            $returnSingle = true;
        }

        $entities = new Collection($entities);
        myQuery = _getQuery($entities, $contain, $source);
        $associations = array_keys(myQuery.getContain());

        $entities = _injectResults($entities, myQuery, $associations, $source);

        return $returnSingle ? array_shift($entities) : $entities;
    }

    /**
     * Builds a query for loading the passed list of entity objects along with the
     * associations specified in $contain.
     *
     * @param \Cake\Collection\ICollection $objects The original entities
     * @param array $contain The associations to be loaded
     * @param \Cake\ORM\Table $source The table to use for fetching the top level entities
     * @return \Cake\ORM\Query
     */
    protected auto _getQuery(ICollection $objects, array $contain, Table $source): Query
    {
        $primaryKey = $source.getPrimaryKey();
        $method = is_string($primaryKey) ? "get" : "extract";

        myKeys = $objects.map(function ($entity) use ($primaryKey, $method) {
            return $entity.{$method}($primaryKey);
        });

        myQuery = $source
            .find()
            .select((array)$primaryKey)
            .where(function ($exp, $q) use ($primaryKey, myKeys, $source) {
                /**
                 * @var \Cake\Database\Expression\QueryExpression $exp
                 * @var \Cake\ORM\Query $q
                 */
                if (is_array($primaryKey) && count($primaryKey) == 1) {
                    $primaryKey = current($primaryKey);
                }

                if (is_string($primaryKey)) {
                    return $exp.in($source.aliasField($primaryKey), myKeys.toList());
                }

                myTypes = array_intersect_key($q.getDefaultTypes(), array_flip($primaryKey));
                $primaryKey = array_map([$source, "aliasField"], $primaryKey);

                return new TupleComparison($primaryKey, myKeys.toList(), myTypes, "IN");
            })
            .enableAutoFields()
            .contain($contain);

        foreach (myQuery.getEagerLoader().attachableAssociations($source) as $loadable) {
            myConfig = $loadable.getConfig();
            myConfig["includeFields"] = true;
            $loadable.setConfig(myConfig);
        }

        return myQuery;
    }

    /**
     * Returns a map of property names where the association results should be injected
     * in the top level entities.
     *
     * @param $source The table having the top level associations
     * @param $associations The name of the top level associations
     */
    protected string[] _getPropertyMap(Table $source, string[] $associations) {
      $map = [];
      myContainer = $source.associations();
      foreach ($associations as $assoc) {
          /** @psalm-suppress PossiblyNullReference */
          $map[$assoc] = myContainer.get($assoc).getProperty();
      }

      return $map;
    }

    /**
     * Injects the results of the eager loader query into the original list of
     * entities.
     *
     * @param \Traversable|array<\Cake\Datasource\IEntity> $objects The original list of entities
     * @param \Cake\ORM\Query myResults The loaded results
     * @param $associations The top level associations that were loaded
     * @param \Cake\ORM\Table $source The table where the entities came from
     * @return array
     */
    protected array _injectResults(iterable $objects, myResults, string[] $associations, Table $source) {
        $injected = [];
        $properties = _getPropertyMap($source, $associations);
        $primaryKey = (array)$source.getPrimaryKey();
        myResults = myResults
            .all()
            .indexBy(function ($e) use ($primaryKey) {
                /** @var \Cake\Datasource\IEntity $e */
                return implode(";", $e.extract($primaryKey));
            })
            .toArray();

        foreach ($objects as $k: $object) {
            myKey = implode(";", $object.extract($primaryKey));
            if (!isset(myResults[myKey])) {
                $injected[$k] = $object;
                continue;
            }

            /** @var \Cake\Datasource\IEntity $loaded */
            $loaded = myResults[myKey];
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
