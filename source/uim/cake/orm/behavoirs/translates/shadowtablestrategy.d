module uim.cake.orm.behaviors\Translate;

@safe:
import uim.cake;

/**
 * This class provides a way to translate dynamic data by keeping translations
 * in a separate shadow table where each row corresponds to a row of primary table.
 */
class ShadowTableStrategy : ITranslateStrategy {
    use InstanceConfigTrait;
    use LocatorAwareTrait;
    use TranslateStrategyTrait {
        buildMarshalMap as private _buildMarshalMap;
    }

    /**
     * Default config
     *
     * These are merged with user-provided configuration.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "fields":[],
        "defaultLocale":null,
        "referenceName":null,
        "allowEmptyTranslations":true,
        "onlyTranslated":false,
        "strategy":"subquery",
        "tableLocator":null,
        "validator":false,
    ];

    /**
     * Constructor
     *
     * @param \Cake\ORM\Table myTable Table instance.
     * @param array<string, mixed> myConfig Configuration.
     */
    this(Table myTable, array myConfig = []) {
        myTableAlias = myTable.getAlias();
        [myPlugin] = pluginSplit(myTable.getRegistryAlias(), true);
        myTableReferenceName = myConfig["referenceName"];

        myConfig += [
            "mainTableAlias":myTableAlias,
            "translationTable":myPlugin . myTableReferenceName . "Translations",
            "hasOneAlias":myTableAlias . "Translation",
        ];

        if (isset(myConfig["tableLocator"])) {
            _tableLocator = myConfig["tableLocator"];
        }

        this.setConfig(myConfig);
        this.table = myTable;
        this.translationTable = this.getTableLocator().get(
            _config["translationTable"],
            ["allowFallbackClass":true]
        );

        this.setupAssociations();
    }

    /**
     * Create a hasMany association for all records.
     *
     * Don"t create a hasOne association here as the join conditions are modified
     * in before find - so create/modify it there.
     *
     * @return void
     */
    protected auto setupAssociations() {
        myConfig = this.getConfig();

        myTargetAlias = this.translationTable.getAlias();
        this.table.hasMany(myTargetAlias, [
            "className":myConfig["translationTable"],
            "foreignKey":"id",
            "strategy":myConfig["strategy"],
            "propertyName":"_i18n",
            "dependent":true,
        ]);
    }

    /**
     * Callback method that listens to the `beforeFind` event in the bound
     * table. It modifies the passed query by eager loading the translated fields
     * and adding a formatter to copy the values into the main table records.
     *
     * @param \Cake\Event\IEvent myEvent The beforeFind event that was fired.
     * @param \Cake\ORM\Query myQuery Query.
     * @param \ArrayObject myOptions The options for the query.
     * @return void
     */
    function beforeFind(IEvent myEvent, Query myQuery, ArrayObject myOptions) {
        $locale = Hash::get(myOptions, "locale", this.locale());
        myConfig = this.getConfig();

        if ($locale == myConfig["defaultLocale"]) {
            return;
        }

        this.setupHasOneAssociation($locale, myOptions);

        myFieldsAdded = this.addFieldsToQuery(myQuery, myConfig);
        $orderByTranslatedField = this.iterateClause(myQuery, "order", myConfig);
        $filteredByTranslatedField =
            this.traverseClause(myQuery, "where", myConfig) ||
            myConfig["onlyTranslated"] ||
            (myOptions["filterByCurrentLocale"] ?? null);

        if (!myFieldsAdded && !$orderByTranslatedField && !$filteredByTranslatedField) {
            return;
        }

        myQuery.contain([myConfig["hasOneAlias"]]);

        myQuery.formatResults(function (myResults) use ($locale) {
            return this.rowMapper(myResults, $locale);
        }, myQuery::PREPEND);
    }

    /**
     * Create a hasOne association for record with required locale.
     *
     * @param string locale Locale
     * @param \ArrayObject myOptions Find options
     */
    protected void setupHasOneAssociation(string locale, ArrayObject myOptions) {
        myConfig = this.getConfig();

        [myPlugin] = pluginSplit(myConfig["translationTable"]);
        $hasOneTargetAlias = myPlugin ? (myPlugin . "." . myConfig["hasOneAlias"]) : myConfig["hasOneAlias"];
        if (!this.getTableLocator().exists($hasOneTargetAlias)) {
            // Load table before hand with fallback class usage enabled
            this.getTableLocator().get(
                $hasOneTargetAlias,
                [
                    "className":myConfig["translationTable"],
                    "allowFallbackClass":true,
                ]
            );
        }

        if (isset(myOptions["filterByCurrentLocale"])) {
            $joinType = myOptions["filterByCurrentLocale"] ? "INNER" : "LEFT";
        } else {
            $joinType = myConfig["onlyTranslated"] ? "INNER" : "LEFT";
        }

        this.table.hasOne(myConfig["hasOneAlias"], [
            "foreignKey":["id"],
            "joinType":$joinType,
            "propertyName":"translation",
            "className":myConfig["translationTable"],
            "conditions":[
                myConfig["hasOneAlias"] . ".locale":$locale,
            ],
        ]);
    }

    /**
     * Add translation fields to query.
     *
     * If the query is using autofields (directly or implicitly) add the
     * main table"s fields to the query first.
     *
     * Only add translations for fields that are in the main table, always
     * add the locale field though.
     *
     * @param \Cake\ORM\Query myQuery The query to check.
     * @param array<string, mixed> myConfig The config to use for adding fields.
     * @return bool Whether a join to the translation table is required.
     */
    protected auto addFieldsToQuery(myQuery, array myConfig) {
        if (myQuery.isAutoFieldsEnabled()) {
            return true;
        }

        $select = array_filter(myQuery.clause("select"), function (myField) {
            return is_string(myField);
        });

        if (!$select) {
            return true;
        }

        myAlias = myConfig["mainTableAlias"];
        $joinRequired = false;
        foreach (this.translatedFields() as myField) {
            if (array_intersect($select, [myField, "myAlias.myField"])) {
                $joinRequired = true;
                myQuery.select(myQuery.aliasField(myField, myConfig["hasOneAlias"]));
            }
        }

        if ($joinRequired) {
            myQuery.select(myQuery.aliasField("locale", myConfig["hasOneAlias"]));
        }

        return $joinRequired;
    }

    /**
     * Iterate over a clause to alias fields.
     *
     * The objective here is to transparently prevent ambiguous field errors by
     * prefixing fields with the appropriate table alias. This method currently
     * expects to receive an order clause only.
     *
     * @param \Cake\ORM\Query myQuery the query to check.
     * @param string myName The clause name.
     * @param array<string, mixed> myConfig The config to use for adding fields.
     * @return bool Whether a join to the translation table is required.
     */
    protected bool iterateClause(myQuery, myName = "", myConfig = []) {
        $clause = myQuery.clause(myName);
        if (!$clause || !$clause.count()) {
            return false;
        }

        myAlias = myConfig["hasOneAlias"];
        myFields = this.translatedFields();
        $mainTableAlias = myConfig["mainTableAlias"];
        $mainTableFields = this.mainFields();
        $joinRequired = false;

        $clause.iterateParts(
            function ($c, &myField) use (myFields, myAlias, $mainTableAlias, $mainTableFields, &$joinRequired) {
                if (!is_string(myField) || indexOf(myField, ".")) {
                    return $c;
                }

                /** @psalm-suppress ParadoxicalCondition */
                if (in_array(myField, myFields, true)) {
                    $joinRequired = true;
                    myField = "myAlias.myField";
                } elseif (in_array(myField, $mainTableFields, true)) {
                    myField = "$mainTableAlias.myField";
                }

                return $c;
            }
        );

        return $joinRequired;
    }

    /**
     * Traverse over a clause to alias fields.
     *
     * The objective here is to transparently prevent ambiguous field errors by
     * prefixing fields with the appropriate table alias. This method currently
     * expects to receive a where clause only.
     *
     * @param \Cake\ORM\Query myQuery the query to check.
     * @param string myName The clause name.
     * @param array<string, mixed> myConfig The config to use for adding fields.
     * @return bool Whether a join to the translation table is required.
     */
    protected bool traverseClause(myQuery, myName = "", myConfig = []) {
        $clause = myQuery.clause(myName);
        if (!$clause || !$clause.count()) {
            return false;
        }

        myAlias = myConfig["hasOneAlias"];
        myFields = this.translatedFields();
        $mainTableAlias = myConfig["mainTableAlias"];
        $mainTableFields = this.mainFields();
        $joinRequired = false;

        $clause.traverse(
            function ($expression) use (myFields, myAlias, $mainTableAlias, $mainTableFields, &$joinRequired) {
                if (!($expression instanceof FieldInterface)) {
                    return;
                }
                myField = $expression.getField();
                if (!is_string(myField) || indexOf(myField, ".")) {
                    return;
                }

                if (in_array(myField, myFields, true)) {
                    $joinRequired = true;
                    $expression.setField("myAlias.myField");

                    return;
                }

                /** @psalm-suppress ParadoxicalCondition */
                if (in_array(myField, $mainTableFields, true)) {
                    $expression.setField("$mainTableAlias.myField");
                }
            }
        );

        return $joinRequired;
    }

    /**
     * Modifies the entity before it is saved so that translated fields are persisted
     * in the database too.
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired.
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved.
     * @param \ArrayObject myOptions the options passed to the save method.
     * @return void
     */
    function beforeSave(IEvent myEvent, IEntity $entity, ArrayObject myOptions) {
        $locale = $entity.get("_locale") ?: this.locale();
        $newOptions = [this.translationTable.getAlias(): ["validate":false]];
        myOptions["associated"] = $newOptions + myOptions["associated"];

        // Check early if empty translations are present in the entity.
        // If this is the case, unset them to prevent persistence.
        // This only applies if _config["allowEmptyTranslations"] is false
        if (_config["allowEmptyTranslations"] == false) {
            this.unsetEmptyFields($entity);
        }

        this.bundleTranslatedFields($entity);
        $bundled = $entity.get("_i18n") ?: [];
        $noBundled = count($bundled) == 0;

        // No additional translation records need to be saved,
        // as the entity is in the default locale.
        if ($noBundled && $locale == this.getConfig("defaultLocale")) {
            return;
        }

        myValues = $entity.extract(this.translatedFields(), true);
        myFields = array_keys(myValues);
        $noFields = empty(myFields);

        // If there are no fields and no bundled translations, or both fields
        // in the default locale and bundled translations we can
        // skip the remaining logic as its not necessary.
        if ($noFields && $noBundled || (myFields && $bundled)) {
            return;
        }

        $primaryKey = (array)this.table.getPrimaryKey();
        $id = $entity.get(current($primaryKey));

        // When we have no key and bundled translations, we
        // need to mark the entity dirty so the root
        // entity persists.
        if ($noFields && $bundled && !$id) {
            foreach (this.translatedFields() as myField) {
                $entity.setDirty(myField, true);
            }

            return;
        }

        if ($noFields) {
            return;
        }

        $where = ["locale":$locale];
        $translation = null;
        if ($id) {
            $where["id"] = $id;

            /** @var \Cake\Datasource\IEntity|null $translation */
            $translation = this.translationTable.find()
                .select(array_merge(["id", "locale"], myFields))
                .where($where)
                .disableBufferedResults()
                .first();
        }

        if ($translation) {
            $translation.set(myValues);
        } else {
            $translation = this.translationTable.newEntity(
                $where + myValues,
                [
                    "useSetters":false,
                    "markNew":true,
                ]
            );
        }

        $entity.set("_i18n", array_merge($bundled, [$translation]));
        $entity.set("_locale", $locale, ["setter":false]);
        $entity.setDirty("_locale", false);

        foreach (myFields as myField) {
            $entity.setDirty(myField, false);
        }
    }


    function buildMarshalMap(Marshaller $marshaller, array $map, array myOptions): array
    {
        this.translatedFields();

        return _buildMarshalMap($marshaller, $map, myOptions);
    }

    /**
     * Returns a fully aliased field name for translated fields.
     *
     * If the requested field is configured as a translation field, field with
     * an alias of a corresponding association is returned. Table-aliased
     * field name is returned for all other fields.
     *
     * @param string myField Field name to be aliased.
     */
    string translationField(string myField) {
        if (this.locale() == this.getConfig("defaultLocale")) {
            return this.table.aliasField(myField);
        }

        $translatedFields = this.translatedFields();
        if (in_array(myField, $translatedFields, true)) {
            return this.getConfig("hasOneAlias") . "." . myField;
        }

        return this.table.aliasField(myField);
    }

    /**
     * Modifies the results from a table find in order to merge the translated
     * fields into each entity for a given locale.
     *
     * @param \Cake\Datasource\IResultSet myResults Results to map.
     * @param string locale Locale string
     * @return \Cake\Collection\ICollection
     */
    protected auto rowMapper(myResults, $locale) {
        $allowEmpty = _config["allowEmptyTranslations"];

        return myResults.map(function ($row) use ($allowEmpty, $locale) {
            /** @var \Cake\Datasource\IEntity|array|null $row */
            if ($row == null) {
                return $row;
            }

            $hydrated = !is_array($row);

            if (empty($row["translation"])) {
                $row["_locale"] = $locale;
                unset($row["translation"]);

                if ($hydrated) {
                    /** @psalm-suppress PossiblyInvalidMethodCall */
                    $row.clean();
                }

                return $row;
            }

            /** @var \Cake\ORM\Entity|array $translation */
            $translation = $row["translation"];

            /**
             * @psalm-suppress PossiblyInvalidMethodCall
             * @psalm-suppress PossiblyInvalidArgument
             */
            myKeys = $hydrated ? $translation.getVisible() : array_keys($translation);

            foreach (myKeys as myField) {
                if (myField == "locale") {
                    $row["_locale"] = $translation[myField];
                    continue;
                }

                if ($translation[myField] !== null) {
                    if ($allowEmpty || $translation[myField] !== "") {
                        $row[myField] = $translation[myField];
                    }
                }
            }

            unset($row["translation"]);

            if ($hydrated) {
                /** @psalm-suppress PossiblyInvalidMethodCall */
                $row.clean();
            }

            return $row;
        });
    }

    /**
     * Modifies the results from a table find in order to merge full translation
     * records into each entity under the `_translations` key.
     *
     * @param \Cake\Datasource\IResultSet myResults Results to modify.
     * @return \Cake\Collection\ICollection
     */
    ICollection groupTranslations(myResults) {
        return myResults.map(function ($row) {
            $translations = (array)$row["_i18n"];
            if (empty($translations) && $row.get("_translations")) {
                return $row;
            }

            myResult = [];
            foreach ($translations as $translation) {
                unset($translation["id"]);
                myResult[$translation["locale"]] = $translation;
            }

            $row["_translations"] = myResult;
            unset($row["_i18n"]);
            if ($row instanceof IEntity) {
                $row.clean();
            }

            return $row;
        });
    }

    /**
     * Helper method used to generated multiple translated field entities
     * out of the data found in the `_translations` property in the passed
     * entity. The result will be put into its `_i18n` property.
     *
     * @param \Cake\Datasource\IEntity $entity Entity.
     * @return void
     */
    protected auto bundleTranslatedFields($entity) {
        $translations = (array)$entity.get("_translations");

        if (empty($translations) && !$entity.isDirty("_translations")) {
            return;
        }

        $primaryKey = (array)this.table.getPrimaryKey();
        myKey = $entity.get(current($primaryKey));

        foreach ($translations as $lang: $translation) {
            if (!$translation.id) {
                $update = [
                    "id":myKey,
                    "locale":$lang,
                ];
                $translation.set($update, ["guard":false]);
            }
        }

        $entity.set("_i18n", $translations);
    }

    /**
     * Lazy define and return the main table fields.
     *
     * @return array
     */
    protected auto mainFields() {
        myFields = this.getConfig("mainTableFields");

        if (myFields) {
            return myFields;
        }

        myFields = this.table.getSchema().columns();

        this.setConfig("mainTableFields", myFields);

        return myFields;
    }

    /**
     * Lazy define and return the translation table fields.
     *
     * @return array
     */
    protected auto translatedFields() {
        myFields = this.getConfig("fields");

        if (myFields) {
            return myFields;
        }

        myTable = this.translationTable;
        myFields = myTable.getSchema().columns();
        myFields = array_values(array_diff(myFields, ["id", "locale"]));

        this.setConfig("fields", myFields);

        return myFields;
    }
}
