

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Behavior;

use Cake\Collection\CollectionInterface;
use Cake\Database\Expression\IdentifierExpression;
use Cake\Datasource\EntityInterface;
use Cake\Datasource\Exception\RecordNotFoundException;
use Cake\Event\EventInterface;
use Cake\ORM\Behavior;
use Cake\ORM\Query;
use InvalidArgumentException;
use RuntimeException;

/**
 * Makes the table to which this is attached to behave like a nested set and
 * provides methods for managing and retrieving information out of the derived
 * hierarchical structure.
 *
 * Tables attaching this behavior are required to have a column referencing the
 * parent row, and two other numeric columns (lft and rght) where the implicit
 * order will be cached.
 *
 * For more information on what is a nested set and a how it works refer to
 * https://www.sitepoint.com/hierarchical-data-database-2/
 */
class TreeBehavior : Behavior
{
    /**
     * Cached copy of the first column in a table"s primary key.
     *
     * @var string
     */
    protected $_primaryKey;

    /**
     * Default config
     *
     * These are merged with user-provided configuration when the behavior is used.
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        "implementedFinders": [
            "path": "findPath",
            "children": "findChildren",
            "treeList": "findTreeList",
        ],
        "implementedMethods": [
            "childCount": "childCount",
            "moveUp": "moveUp",
            "moveDown": "moveDown",
            "recover": "recover",
            "removeFromTree": "removeFromTree",
            "getLevel": "getLevel",
            "formatTreeList": "formatTreeList",
        ],
        "parent": "parent_id",
        "left": "lft",
        "right": "rght",
        "scope": null,
        "level": null,
        "recoverOrder": null,
        "cascadeCallbacks": false,
    ];

    /**
     * @inheritDoc
     */
    function initialize(array $config): void
    {
        _config["leftField"] = new IdentifierExpression(_config["left"]);
        _config["rightField"] = new IdentifierExpression(_config["right"]);
    }

    /**
     * Before save listener.
     * Transparently manages setting the lft and rght fields if the parent field is
     * included in the parameters to be saved.
     *
     * @param \Cake\Event\IEvent $event The beforeSave event that was fired
     * @param \Cake\Datasource\EntityInterface $entity the entity that is going to be saved
     * @return void
     * @throws \RuntimeException if the parent to set for the node is invalid
     */
    function beforeSave(IEvent $event, EntityInterface $entity)
    {
        $isNew = $entity.isNew();
        $config = this.getConfig();
        $parent = $entity.get($config["parent"]);
        $primaryKey = _getPrimaryKey();
        $dirty = $entity.isDirty($config["parent"]);
        $level = $config["level"];

        if ($parent && $entity.get($primaryKey) == $parent) {
            throw new RuntimeException("Cannot set a node"s parent as itself");
        }

        if ($isNew && $parent) {
            $parentNode = _getNode($parent);
            $edge = $parentNode.get($config["right"]);
            $entity.set($config["left"], $edge);
            $entity.set($config["right"], $edge + 1);
            _sync(2, "+", ">= {$edge}");

            if ($level) {
                $entity.set($level, $parentNode[$level] + 1);
            }

            return;
        }

        if ($isNew && !$parent) {
            $edge = _getMax();
            $entity.set($config["left"], $edge + 1);
            $entity.set($config["right"], $edge + 2);

            if ($level) {
                $entity.set($level, 0);
            }

            return;
        }

        if ($dirty && $parent) {
            _setParent($entity, $parent);

            if ($level) {
                $parentNode = _getNode($parent);
                $entity.set($level, $parentNode[$level] + 1);
            }

            return;
        }

        if ($dirty && !$parent) {
            _setAsRoot($entity);

            if ($level) {
                $entity.set($level, 0);
            }
        }
    }

    /**
     * After save listener.
     *
     * Manages updating level of descendants of currently saved entity.
     *
     * @param \Cake\Event\IEvent $event The afterSave event that was fired
     * @param \Cake\Datasource\EntityInterface $entity the entity that is going to be saved
     * @return void
     */
    function afterSave(IEvent $event, EntityInterface $entity)
    {
        if (!_config["level"] || $entity.isNew()) {
            return;
        }

        _setChildrenLevel($entity);
    }

    /**
     * Set level for descendants.
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity whose descendants need to be updated.
     * @return void
     */
    protected function _setChildrenLevel(EntityInterface $entity): void
    {
        $config = this.getConfig();

        if ($entity.get($config["left"]) + 1 == $entity.get($config["right"])) {
            return;
        }

        $primaryKey = _getPrimaryKey();
        $primaryKeyValue = $entity.get($primaryKey);
        $depths = [$primaryKeyValue: $entity.get($config["level"])];

        $children = _table.find("children", [
            "for": $primaryKeyValue,
            "fields": [_getPrimaryKey(), $config["parent"], $config["level"]],
            "order": $config["left"],
        ]);

        /** @var \Cake\Datasource\EntityInterface $node */
        foreach ($children as $node) {
            $parentIdValue = $node.get($config["parent"]);
            $depth = $depths[$parentIdValue] + 1;
            $depths[$node.get($primaryKey)] = $depth;

            _table.updateAll(
                [$config["level"]: $depth],
                [$primaryKey: $node.get($primaryKey)]
            );
        }
    }

    /**
     * Also deletes the nodes in the subtree of the entity to be delete
     *
     * @param \Cake\Event\IEvent $event The beforeDelete event that was fired
     * @param \Cake\Datasource\EntityInterface $entity The entity that is going to be saved
     * @return void
     */
    function beforeDelete(IEvent $event, EntityInterface $entity)
    {
        $config = this.getConfig();
        _ensureFields($entity);
        $left = $entity.get($config["left"]);
        $right = $entity.get($config["right"]);
        $diff = $right - $left + 1;

        if ($diff > 2) {
            $query = _scope(_table.query())
                .where(function ($exp) use ($config, $left, $right) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp
                        .gte($config["leftField"], $left + 1)
                        .lte($config["leftField"], $right - 1);
                });
            if (this.getConfig("cascadeCallbacks")) {
                $entities = $query.toArray();
                foreach ($entities as $entityToDelete) {
                    _table.delete($entityToDelete, ["atomic": false]);
                }
            } else {
                $query.delete();
                $statement = $query.execute();
                $statement.closeCursor();
            }
        }

        _sync($diff, "-", "> {$right}");
    }

    /**
     * Sets the correct left and right values for the passed entity so it can be
     * updated to a new parent. It also makes the hole in the tree so the node
     * move can be done without corrupting the structure.
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity to re-parent
     * @param mixed $parent the id of the parent to set
     * @return void
     * @throws \RuntimeException if the parent to set to the entity is not valid
     */
    protected function _setParent(EntityInterface $entity, $parent): void
    {
        $config = this.getConfig();
        $parentNode = _getNode($parent);
        _ensureFields($entity);
        $parentLeft = $parentNode.get($config["left"]);
        $parentRight = $parentNode.get($config["right"]);
        $right = $entity.get($config["right"]);
        $left = $entity.get($config["left"]);

        if ($parentLeft > $left && $parentLeft < $right) {
            throw new RuntimeException(sprintf(
                "Cannot use node "%s" as parent for entity "%s"",
                $parent,
                $entity.get(_getPrimaryKey())
            ));
        }

        // Values for moving to the left
        $diff = $right - $left + 1;
        $targetLeft = $parentRight;
        $targetRight = $diff + $parentRight - 1;
        $min = $parentRight;
        $max = $left - 1;

        if ($left < $targetLeft) {
            // Moving to the right
            $targetLeft = $parentRight - $diff;
            $targetRight = $parentRight - 1;
            $min = $right + 1;
            $max = $parentRight - 1;
            $diff *= -1;
        }

        if ($right - $left > 1) {
            // Correcting internal subtree
            $internalLeft = $left + 1;
            $internalRight = $right - 1;
            _sync($targetLeft - $left, "+", "BETWEEN {$internalLeft} AND {$internalRight}", true);
        }

        _sync($diff, "+", "BETWEEN {$min} AND {$max}");

        if ($right - $left > 1) {
            _unmarkInternalTree();
        }

        // Allocating new position
        $entity.set($config["left"], $targetLeft);
        $entity.set($config["right"], $targetRight);
    }

    /**
     * Updates the left and right column for the passed entity so it can be set as
     * a new root in the tree. It also modifies the ordering in the rest of the tree
     * so the structure remains valid
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity to set as a new root
     * @return void
     */
    protected function _setAsRoot(EntityInterface $entity): void
    {
        $config = this.getConfig();
        $edge = _getMax();
        _ensureFields($entity);
        $right = $entity.get($config["right"]);
        $left = $entity.get($config["left"]);
        $diff = $right - $left;

        if ($right - $left > 1) {
            //Correcting internal subtree
            $internalLeft = $left + 1;
            $internalRight = $right - 1;
            _sync($edge - $diff - $left, "+", "BETWEEN {$internalLeft} AND {$internalRight}", true);
        }

        _sync($diff + 1, "-", "BETWEEN {$right} AND {$edge}");

        if ($right - $left > 1) {
            _unmarkInternalTree();
        }

        $entity.set($config["left"], $edge - $diff);
        $entity.set($config["right"], $edge);
    }

    /**
     * Helper method used to invert the sign of the left and right columns that are
     * less than 0. They were set to negative values before so their absolute value
     * wouldn"t change while performing other tree transformations.
     *
     * @return void
     */
    protected function _unmarkInternalTree(): void
    {
        $config = this.getConfig();
        _table.updateAll(
            function ($exp) use ($config) {
                /** @var \Cake\Database\Expression\QueryExpression $exp */
                $leftInverse = clone $exp;
                $leftInverse.setConjunction("*").add("-1");
                $rightInverse = clone $leftInverse;

                return $exp
                    .eq($config["leftField"], $leftInverse.add($config["leftField"]))
                    .eq($config["rightField"], $rightInverse.add($config["rightField"]));
            },
            function ($exp) use ($config) {
                /** @var \Cake\Database\Expression\QueryExpression $exp */
                return $exp.lt($config["leftField"], 0);
            }
        );
    }

    /**
     * Custom finder method which can be used to return the list of nodes from the root
     * to a specific node in the tree. This custom finder requires that the key "for"
     * is passed in the options containing the id of the node to get its path for.
     *
     * @param \Cake\ORM\Query $query The constructed query to modify
     * @param array<string, mixed> $options the list of options for the query
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException If the "for" key is missing in options
     */
    function findPath(Query $query, array $options): Query
    {
        if (empty($options["for"])) {
            throw new InvalidArgumentException("The "for" key is required for find("path")");
        }

        $config = this.getConfig();
        [$left, $right] = array_map(
            function ($field) {
                return _table.aliasField($field);
            },
            [$config["left"], $config["right"]]
        );

        $node = _table.get($options["for"], ["fields": [$left, $right]]);

        return _scope($query)
            .where([
                "$left <=": $node.get($config["left"]),
                "$right >=": $node.get($config["right"]),
            ])
            .order([$left: "ASC"]);
    }

    /**
     * Get the number of children nodes.
     *
     * @param \Cake\Datasource\EntityInterface $node The entity to count children for
     * @param bool $direct whether to count all nodes in the subtree or just
     * direct children
     * @return int Number of children nodes.
     */
    function childCount(EntityInterface $node, bool $direct = false): int
    {
        $config = this.getConfig();
        $parent = _table.aliasField($config["parent"]);

        if ($direct) {
            return _scope(_table.find())
                .where([$parent: $node.get(_getPrimaryKey())])
                .count();
        }

        _ensureFields($node);

        return ($node.get($config["right"]) - $node.get($config["left"]) - 1) / 2;
    }

    /**
     * Get the children nodes of the current model
     *
     * Available options are:
     *
     * - for: The id of the record to read.
     * - direct: Boolean, whether to return only the direct (true), or all (false) children,
     *   defaults to false (all children).
     *
     * If the direct option is set to true, only the direct children are returned (based upon the parent_id field)
     *
     * @param \Cake\ORM\Query $query Query.
     * @param array<string, mixed> $options Array of options as described above
     * @return \Cake\ORM\Query
     * @throws \InvalidArgumentException When the "for" key is not passed in $options
     */
    function findChildren(Query $query, array $options): Query
    {
        $config = this.getConfig();
        $options += ["for": null, "direct": false];
        [$parent, $left, $right] = array_map(
            function ($field) {
                return _table.aliasField($field);
            },
            [$config["parent"], $config["left"], $config["right"]]
        );

        [$for, $direct] = [$options["for"], $options["direct"]];

        if (empty($for)) {
            throw new InvalidArgumentException("The "for" key is required for find("children")");
        }

        if ($query.clause("order") == null) {
            $query.order([$left: "ASC"]);
        }

        if ($direct) {
            return _scope($query).where([$parent: $for]);
        }

        $node = _getNode($for);

        return _scope($query)
            .where([
                "{$right} <": $node.get($config["right"]),
                "{$left} >": $node.get($config["left"]),
            ]);
    }

    /**
     * Gets a representation of the elements in the tree as a flat list where the keys are
     * the primary key for the table and the values are the display field for the table.
     * Values are prefixed to visually indicate relative depth in the tree.
     *
     * ### Options
     *
     * - keyPath: A dot separated path to fetch the field to use for the array key, or a closure to
     *   return the key out of the provided row.
     * - valuePath: A dot separated path to fetch the field to use for the array value, or a closure to
     *   return the value out of the provided row.
     * - spacer: A string to be used as prefix for denoting the depth in the tree for each item
     *
     * @param \Cake\ORM\Query $query Query.
     * @param array<string, mixed> $options Array of options as described above.
     * @return \Cake\ORM\Query
     */
    function findTreeList(Query $query, array $options): Query
    {
        $left = _table.aliasField(this.getConfig("left"));

        $results = _scope($query)
            .find("threaded", [
                "parentField": this.getConfig("parent"),
                "order": [$left: "ASC"],
            ]);

        return this.formatTreeList($results, $options);
    }

    /**
     * Formats query as a flat list where the keys are the primary key for the table
     * and the values are the display field for the table. Values are prefixed to visually
     * indicate relative depth in the tree.
     *
     * ### Options
     *
     * - keyPath: A dot separated path to the field that will be the result array key, or a closure to
     *   return the key from the provided row.
     * - valuePath: A dot separated path to the field that is the array"s value, or a closure to
     *   return the value from the provided row.
     * - spacer: A string to be used as prefix for denoting the depth in the tree for each item.
     *
     * @param \Cake\ORM\Query $query The query object to format.
     * @param array<string, mixed> $options Array of options as described above.
     * @return \Cake\ORM\Query Augmented query.
     */
    function formatTreeList(Query $query, array $options = []): Query
    {
        return $query.formatResults(function (CollectionInterface $results) use ($options) {
            $options += [
                "keyPath": _getPrimaryKey(),
                "valuePath": _table.getDisplayField(),
                "spacer": "_",
            ];

            /** @var \Cake\Collection\Iterator\TreeIterator $nested */
            $nested = $results.listNested();

            return $nested.printer($options["valuePath"], $options["keyPath"], $options["spacer"]);
        });
    }

    /**
     * Removes the current node from the tree, by positioning it as a new root
     * and re-parents all children up one level.
     *
     * Note that the node will not be deleted just moved away from its current position
     * without moving its children with it.
     *
     * @param \Cake\Datasource\EntityInterface $node The node to remove from the tree
     * @return \Cake\Datasource\EntityInterface|false the node after being removed from the tree or
     * false on error
     */
    function removeFromTree(EntityInterface $node)
    {
        return _table.getConnection().transactional(function () use ($node) {
            _ensureFields($node);

            return _removeFromTree($node);
        });
    }

    /**
     * Helper function containing the actual code for removeFromTree
     *
     * @param \Cake\Datasource\EntityInterface $node The node to remove from the tree
     * @return \Cake\Datasource\EntityInterface|false the node after being removed from the tree or
     * false on error
     */
    protected function _removeFromTree(EntityInterface $node)
    {
        $config = this.getConfig();
        $left = $node.get($config["left"]);
        $right = $node.get($config["right"]);
        $parent = $node.get($config["parent"]);

        $node.set($config["parent"], null);

        if ($right - $left == 1) {
            return _table.save($node);
        }

        $primary = _getPrimaryKey();
        _table.updateAll(
            [$config["parent"]: $parent],
            [$config["parent"]: $node.get($primary)]
        );
        _sync(1, "-", "BETWEEN " . ($left + 1) . " AND " . ($right - 1));
        _sync(2, "-", "> {$right}");
        $edge = _getMax();
        $node.set($config["left"], $edge + 1);
        $node.set($config["right"], $edge + 2);
        $fields = [$config["parent"], $config["left"], $config["right"]];

        _table.updateAll($node.extract($fields), [$primary: $node.get($primary)]);

        foreach ($fields as $field) {
            $node.setDirty($field, false);
        }

        return $node;
    }

    /**
     * Reorders the node without changing its parent.
     *
     * If the node is the first child, or is a top level node with no previous node
     * this method will return the same node without any changes
     *
     * @param \Cake\Datasource\EntityInterface $node The node to move
     * @param int|true $number How many places to move the node, or true to move to first position
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @return \Cake\Datasource\EntityInterface|false $node The node after being moved or false if `$number` is < 1
     */
    function moveUp(EntityInterface $node, $number = 1)
    {
        if ($number < 1) {
            return false;
        }

        return _table.getConnection().transactional(function () use ($node, $number) {
            _ensureFields($node);

            return _moveUp($node, $number);
        });
    }

    /**
     * Helper function used with the actual code for moveUp
     *
     * @param \Cake\Datasource\EntityInterface $node The node to move
     * @param int|true $number How many places to move the node, or true to move to first position
     * @return \Cake\Datasource\EntityInterface $node The node after being moved
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     */
    protected function _moveUp(EntityInterface $node, $number): EntityInterface
    {
        $config = this.getConfig();
        [$parent, $left, $right] = [$config["parent"], $config["left"], $config["right"]];
        [$nodeParent, $nodeLeft, $nodeRight] = array_values($node.extract([$parent, $left, $right]));

        $targetNode = null;
        if ($number != true) {
            /** @var \Cake\Datasource\EntityInterface|null $targetNode */
            $targetNode = _scope(_table.find())
                .select([$left, $right])
                .where(["$parent IS": $nodeParent])
                .where(function ($exp) use ($config, $nodeLeft) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.lt($config["rightField"], $nodeLeft);
                })
                .orderDesc($config["leftField"])
                .offset($number - 1)
                .limit(1)
                .first();
        }
        if (!$targetNode) {
            /** @var \Cake\Datasource\EntityInterface|null $targetNode */
            $targetNode = _scope(_table.find())
                .select([$left, $right])
                .where(["$parent IS": $nodeParent])
                .where(function ($exp) use ($config, $nodeLeft) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.lt($config["rightField"], $nodeLeft);
                })
                .orderAsc($config["leftField"])
                .limit(1)
                .first();

            if (!$targetNode) {
                return $node;
            }
        }

        [$targetLeft] = array_values($targetNode.extract([$left, $right]));
        $edge = _getMax();
        $leftBoundary = $targetLeft;
        $rightBoundary = $nodeLeft - 1;

        $nodeToEdge = $edge - $nodeLeft + 1;
        $shift = $nodeRight - $nodeLeft + 1;
        $nodeToHole = $edge - $leftBoundary + 1;
        _sync($nodeToEdge, "+", "BETWEEN {$nodeLeft} AND {$nodeRight}");
        _sync($shift, "+", "BETWEEN {$leftBoundary} AND {$rightBoundary}");
        _sync($nodeToHole, "-", "> {$edge}");

        $node.set($left, $targetLeft);
        $node.set($right, $targetLeft + $nodeRight - $nodeLeft);

        $node.setDirty($left, false);
        $node.setDirty($right, false);

        return $node;
    }

    /**
     * Reorders the node without changing the parent.
     *
     * If the node is the last child, or is a top level node with no subsequent node
     * this method will return the same node without any changes
     *
     * @param \Cake\Datasource\EntityInterface $node The node to move
     * @param int|true $number How many places to move the node or true to move to last position
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @return \Cake\Datasource\EntityInterface|false the entity after being moved or false if `$number` is < 1
     */
    function moveDown(EntityInterface $node, $number = 1)
    {
        if ($number < 1) {
            return false;
        }

        return _table.getConnection().transactional(function () use ($node, $number) {
            _ensureFields($node);

            return _moveDown($node, $number);
        });
    }

    /**
     * Helper function used with the actual code for moveDown
     *
     * @param \Cake\Datasource\EntityInterface $node The node to move
     * @param int|true $number How many places to move the node, or true to move to last position
     * @return \Cake\Datasource\EntityInterface $node The node after being moved
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     */
    protected function _moveDown(EntityInterface $node, $number): EntityInterface
    {
        $config = this.getConfig();
        [$parent, $left, $right] = [$config["parent"], $config["left"], $config["right"]];
        [$nodeParent, $nodeLeft, $nodeRight] = array_values($node.extract([$parent, $left, $right]));

        $targetNode = null;
        if ($number != true) {
            /** @var \Cake\Datasource\EntityInterface|null $targetNode */
            $targetNode = _scope(_table.find())
                .select([$left, $right])
                .where(["$parent IS": $nodeParent])
                .where(function ($exp) use ($config, $nodeRight) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.gt($config["leftField"], $nodeRight);
                })
                .orderAsc($config["leftField"])
                .offset($number - 1)
                .limit(1)
                .first();
        }
        if (!$targetNode) {
            /** @var \Cake\Datasource\EntityInterface|null $targetNode */
            $targetNode = _scope(_table.find())
                .select([$left, $right])
                .where(["$parent IS": $nodeParent])
                .where(function ($exp) use ($config, $nodeRight) {
                    /** @var \Cake\Database\Expression\QueryExpression $exp */
                    return $exp.gt($config["leftField"], $nodeRight);
                })
                .orderDesc($config["leftField"])
                .limit(1)
                .first();

            if (!$targetNode) {
                return $node;
            }
        }

        [, $targetRight] = array_values($targetNode.extract([$left, $right]));
        $edge = _getMax();
        $leftBoundary = $nodeRight + 1;
        $rightBoundary = $targetRight;

        $nodeToEdge = $edge - $nodeLeft + 1;
        $shift = $nodeRight - $nodeLeft + 1;
        $nodeToHole = $edge - $rightBoundary + $shift;
        _sync($nodeToEdge, "+", "BETWEEN {$nodeLeft} AND {$nodeRight}");
        _sync($shift, "-", "BETWEEN {$leftBoundary} AND {$rightBoundary}");
        _sync($nodeToHole, "-", "> {$edge}");

        $node.set($left, $targetRight - ($nodeRight - $nodeLeft));
        $node.set($right, $targetRight);

        $node.setDirty($left, false);
        $node.setDirty($right, false);

        return $node;
    }

    /**
     * Returns a single node from the tree from its primary key
     *
     * @param mixed $id Record id.
     * @return \Cake\Datasource\EntityInterface
     * @throws \Cake\Datasource\Exception\RecordNotFoundException When node was not found
     * @psalm-suppress InvalidReturnType
     */
    protected function _getNode($id): EntityInterface
    {
        $config = this.getConfig();
        [$parent, $left, $right] = [$config["parent"], $config["left"], $config["right"]];
        $primaryKey = _getPrimaryKey();
        $fields = [$parent, $left, $right];
        if ($config["level"]) {
            $fields[] = $config["level"];
        }

        $node = _scope(_table.find())
            .select($fields)
            .where([_table.aliasField($primaryKey): $id])
            .first();

        if (!$node) {
            throw new RecordNotFoundException("Node \"{$id}\" was not found in the tree.");
        }

        /** @psalm-suppress InvalidReturnStatement */
        return $node;
    }

    /**
     * Recovers the lft and right column values out of the hierarchy defined by the
     * parent column.
     *
     * @return void
     */
    function recover(): void
    {
        _table.getConnection().transactional(function (): void {
            _recoverTree();
        });
    }

    /**
     * Recursive method used to recover a single level of the tree
     *
     * @param int $lftRght The starting lft/rght value
     * @param mixed $parentId the parent id of the level to be recovered
     * @param int $level Node level
     * @return int The next lftRght value
     */
    protected function _recoverTree(int $lftRght = 1, $parentId = null, $level = 0): int
    {
        $config = this.getConfig();
        [$parent, $left, $right] = [$config["parent"], $config["left"], $config["right"]];
        $primaryKey = _getPrimaryKey();
        $order = $config["recoverOrder"] ?: $primaryKey;

        $nodes = _scope(_table.query())
            .select($primaryKey)
            .where([$parent . " IS": $parentId])
            .order($order)
            .disableHydration()
            .all();

        foreach ($nodes as $node) {
            $nodeLft = $lftRght++;
            $lftRght = _recoverTree($lftRght, $node[$primaryKey], $level + 1);

            $fields = [$left: $nodeLft, $right: $lftRght++];
            if ($config["level"]) {
                $fields[$config["level"]] = $level;
            }

            _table.updateAll(
                $fields,
                [$primaryKey: $node[$primaryKey]]
            );
        }

        return $lftRght;
    }

    /**
     * Returns the maximum index value in the table.
     *
     * @return int
     */
    protected function _getMax(): int
    {
        $field = _config["right"];
        $rightField = _config["rightField"];
        $edge = _scope(_table.find())
            .select([$field])
            .orderDesc($rightField)
            .first();

        if ($edge == null || empty($edge[$field])) {
            return 0;
        }

        return $edge[$field];
    }

    /**
     * Auxiliary function used to automatically alter the value of both the left and
     * right columns by a certain amount that match the passed conditions
     *
     * @param int $shift the value to use for operating the left and right columns
     * @param string $dir The operator to use for shifting the value (+/-)
     * @param string $conditions a SQL snipped to be used for comparing left or right
     * against it.
     * @param bool $mark whether to mark the updated values so that they can not be
     * modified by future calls to this function.
     * @return void
     */
    protected function _sync(int $shift, string $dir, string $conditions, bool $mark = false): void
    {
        $config = _config;

        foreach ([$config["leftField"], $config["rightField"]] as $field) {
            $query = _scope(_table.query());
            $exp = $query.newExpr();

            $movement = clone $exp;
            $movement.add($field).add((string)$shift).setConjunction($dir);

            $inverse = clone $exp;
            $movement = $mark ?
                $inverse.add($movement).setConjunction("*").add("-1") :
                $movement;

            $where = clone $exp;
            $where.add($field).add($conditions).setConjunction("");

            $query.update()
                .set($exp.eq($field, $movement))
                .where($where);

            $query.execute().closeCursor();
        }
    }

    /**
     * Alters the passed query so that it only returns scoped records as defined
     * in the tree configuration.
     *
     * @param \Cake\ORM\Query $query the Query to modify
     * @return \Cake\ORM\Query
     */
    protected function _scope(Query $query): Query
    {
        $scope = this.getConfig("scope");

        if (is_array($scope)) {
            return $query.where($scope);
        }
        if (is_callable($scope)) {
            return $scope($query);
        }

        return $query;
    }

    /**
     * Ensures that the provided entity contains non-empty values for the left and
     * right fields
     *
     * @param \Cake\Datasource\EntityInterface $entity The entity to ensure fields for
     * @return void
     */
    protected function _ensureFields(EntityInterface $entity): void
    {
        $config = this.getConfig();
        $fields = [$config["left"], $config["right"]];
        $values = array_filter($entity.extract($fields));
        if (count($values) == count($fields)) {
            return;
        }

        $fresh = _table.get($entity.get(_getPrimaryKey()));
        $entity.set($fresh.extract($fields), ["guard": false]);

        foreach ($fields as $field) {
            $entity.setDirty($field, false);
        }
    }

    /**
     * Returns a single string value representing the primary key of the attached table
     *
     * @return string
     */
    protected function _getPrimaryKey(): string
    {
        if (!_primaryKey) {
            $primaryKey = (array)_table.getPrimaryKey();
            _primaryKey = $primaryKey[0];
        }

        return _primaryKey;
    }

    /**
     * Returns the depth level of a node in the tree.
     *
     * @param \Cake\Datasource\EntityInterface|string|int $entity The entity or primary key get the level of.
     * @return int|false Integer of the level or false if the node does not exist.
     */
    function getLevel($entity)
    {
        $primaryKey = _getPrimaryKey();
        $id = $entity;
        if ($entity instanceof EntityInterface) {
            $id = $entity.get($primaryKey);
        }
        $config = this.getConfig();
        $entity = _table.find("all")
            .select([$config["left"], $config["right"]])
            .where([$primaryKey: $id])
            .first();

        if ($entity == null) {
            return false;
        }

        $query = _table.find("all").where([
            $config["left"] . " <": $entity[$config["left"]],
            $config["right"] . " >": $entity[$config["right"]],
        ]);

        return _scope($query).count();
    }
}
