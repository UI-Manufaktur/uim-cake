module uim.cake.orm.behaviors\Translate;

@safe:
import uim.cake;

/**
 * This class provides a way to translate dynamic data by keeping translations
 * in a separate table linked to the original record from another one. Translated
 * fields can be configured to override those in the main table when fetched or
 * put aside into another property for the same entity.
 *
 * If you wish to override fields, you need to call the `locale` method in this
 * behavior for setting the language you want to fetch from the translations table.
 *
 * If you want to bring all or certain languages for each of the fetched records,
 * you can use the custom `translations` finder of `TranslateBehavior` that is
 * exposed to the table.
 */
class EavStrategy : ITranslateStrategy
{
    use InstanceConfigTrait;
    use LocatorAwareTrait;
    use TranslateStrategyTrait;

    /**
     * Default config
     *
     * These are merged with user-provided configuration.
     *
     * @var array<string, mixed>
     */
    protected STRINGAA _defaultConfig = [
        "fields":[],
        "translationTable":"I18n",
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
     * @param \Cake\ORM\Table myTable The table this strategy is attached to.
     * @param array<string, mixed> myConfig The config for this strategy.
     */
    this(Table myTable, array myConfig = []) {
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
     * Creates the associations between the bound table and every field passed to
     * this method.
     *
     * Additionally it creates a `i18n` HasMany association that will be
     * used for fetching all translations for each record in the bound table.
     *
     * @return void
     */
    protected auto setupAssociations() {
        myFields = _config["fields"];
        myTable = _config["translationTable"];
        myModel = _config["referenceName"];
        $strategy = _config["strategy"];
        $filter = _config["onlyTranslated"];

        myTargetAlias = this.translationTable.getAlias();
        myAlias = this.table.getAlias();
        myTableLocator = this.getTableLocator();

        foreach (myFields as myField) {
            myName = myAlias . "_" . myField . "_translation";

            if (!myTableLocator.exists(myName)) {
                myFieldTable = myTableLocator.get(myName, [
                    "className":myTable,
                    "alias":myName,
                    "table":this.translationTable.getTable(),
                    "allowFallbackClass":true,
                ]);
            } else {
                myFieldTable = myTableLocator.get(myName);
            }

            $conditions = [
                myName . ".model":myModel,
                myName . ".field":myField,
            ];
            if (!_config["allowEmptyTranslations"]) {
                $conditions[myName . ".content !="] = "";
            }

            this.table.hasOne(myName, [
                "targetTable":myFieldTable,
                "foreignKey":"foreign_key",
                "joinType":$filter ? Query::JOIN_TYPE_INNER : Query::JOIN_TYPE_LEFT,
                "conditions":$conditions,
                "propertyName":myField . "_translation",
            ]);
        }

        $conditions = ["myTargetAlias.model":myModel];
        if (!_config["allowEmptyTranslations"]) {
            $conditions["myTargetAlias.content !="] = "";
        }

        this.table.hasMany(myTargetAlias, [
            "className":myTable,
            "foreignKey":"foreign_key",
            "strategy":$strategy,
            "conditions":$conditions,
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
     * @param \Cake\ORM\Query myQuery Query
     * @param \ArrayObject myOptions The options for the query
     * @return void
     */
    function beforeFind(IEvent myEvent, Query myQuery, ArrayObject myOptions) {
        $locale = Hash::get(myOptions, "locale", this.locale());

        if ($locale == this.getConfig("defaultLocale")) {
            return;
        }

        $conditions = function (myField, $locale, myQuery, $select) {
            return function ($q) use (myField, $locale, myQuery, $select) {
                $q.where([$q.getRepository().aliasField("locale"): $locale]);

                if (
                    myQuery.isAutoFieldsEnabled() ||
                    in_array(myField, $select, true) ||
                    in_array(this.table.aliasField(myField), $select, true)
                ) {
                    $q.select(["id", "content"]);
                }

                return $q;
            };
        };

        $contain = [];
        myFields = _config["fields"];
        myAlias = this.table.getAlias();
        $select = myQuery.clause("select");

        $changeFilter = isset(myOptions["filterByCurrentLocale"]) &&
            myOptions["filterByCurrentLocale"] !== _config["onlyTranslated"];

        foreach (myFields as myField) {
            myName = myAlias . "_" . myField . "_translation";

            $contain[myName]["queryBuilder"] = $conditions(
                myField,
                $locale,
                myQuery,
                $select
            );

            if ($changeFilter) {
                $filter = myOptions["filterByCurrentLocale"]
                    ? Query::JOIN_TYPE_INNER
                    : Query::JOIN_TYPE_LEFT;
                $contain[myName]["joinType"] = $filter;
            }
        }

        myQuery.contain($contain);
        myQuery.formatResults(function (myResults) use ($locale) {
            return this.rowMapper(myResults, $locale);
        }, myQuery::PREPEND);
    }

    /**
     * Modifies the entity before it is saved so that translated fields are persisted
     * in the database too.
     *
     * @param \Cake\Event\IEvent myEvent The beforeSave event that was fired
     * @param \Cake\Datasource\IEntity $entity The entity that is going to be saved
     * @param \ArrayObject myOptions the options passed to the save method
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

        myValues = $entity.extract(_config["fields"], true);
        myFields = array_keys(myValues);
        $noFields = empty(myFields);

        // If there are no fields and no bundled translations, or both fields
        // in the default locale and bundled translations we can
        // skip the remaining logic as its not necessary.
        if ($noFields && $noBundled || (myFields && $bundled)) {
            return;
        }

        $primaryKey = (array)this.table.getPrimaryKey();
        myKey = $entity.get(current($primaryKey));

        // When we have no key and bundled translations, we
        // need to mark the entity dirty so the root
        // entity persists.
        if ($noFields && $bundled && !myKey) {
            foreach (_config["fields"] as myField) {
                $entity.setDirty(myField, true);
            }

            return;
        }

        if ($noFields) {
            return;
        }

        myModel = _config["referenceName"];

        $preexistent = [];
        if (myKey) {
            $preexistent = this.translationTable.find()
                .select(["id", "field"])
                .where([
                    "field IN":myFields,
                    "locale":$locale,
                    "foreign_key":myKey,
                    "model":myModel,
                ])
                .disableBufferedResults()
                .all()
                .indexBy("field");
        }

        $modified = [];
        foreach ($preexistent as myField: $translation) {
            $translation.set("content", myValues[myField]);
            $modified[myField] = $translation;
        }

        $new = array_diff_key(myValues, $modified);
        foreach ($new as myField: myContents) {
            $new[myField] = new Entity(compact("locale", "field", "content", "model"), [
                "useSetters":false,
                "markNew":true,
            ]);
        }

        $entity.set("_i18n", array_merge($bundled, array_values($modified + $new)));
        $entity.set("_locale", $locale, ["setter":false]);
        $entity.setDirty("_locale", false);

        foreach (myFields as myField) {
            $entity.setDirty(myField, false);
        }
    }

    /**
     * Returns a fully aliased field name for translated fields.
     *
     * If the requested field is configured as a translation field, the `content`
     * field with an alias of a corresponding association is returned. Table-aliased
     * field name is returned for all other fields.
     *
     * @param string myField Field name to be aliased.
     */
    string translationField(string myField) {
        myTable = this.table;
        if (this.locale() == this.getConfig("defaultLocale")) {
            return myTable.aliasField(myField);
        }
        $associationName = myTable.getAlias() . "_" . myField . "_translation";

        if (myTable.associations().has($associationName)) {
            return $associationName . ".content";
        }

        return myTable.aliasField(myField);
    }

    /**
     * Modifies the results from a table find in order to merge the translated fields
     * into each entity for a given locale.
     *
     * @param \Cake\Datasource\IResultSet myResults Results to map.
     * @param string locale Locale string
     * @return \Cake\Collection\ICollection
     */
    protected auto rowMapper(myResults, $locale) {
        return myResults.map(function ($row) use ($locale) {
            /** @var \Cake\Datasource\IEntity|array|null $row */
            if ($row == null) {
                return $row;
            }
            $hydrated = !is_array($row);

            foreach (_config["fields"] as myField) {
                myName = myField . "_translation";
                $translation = $row[myName] ?? null;

                if ($translation == null || $translation == false) {
                    unset($row[myName]);
                    continue;
                }

                myContents = $translation["content"] ?? null;
                if (myContents !== null) {
                    $row[myField] = myContents;
                }

                unset($row[myName]);
            }

            $row["_locale"] = $locale;
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
            if (!$row instanceof IEntity) {
                return $row;
            }
            $translations = (array)$row.get("_i18n");
            if (empty($translations) && $row.get("_translations")) {
                return $row;
            }
            myGrouped = new Collection($translations);

            myResult = [];
            foreach (myGrouped.combine("field", "content", "locale") as $locale: myKeys) {
                $entityClass = this.table.getEntityClass();
                $translation = new $entityClass(myKeys + ["locale":$locale], [
                    "markNew":false,
                    "useSetters":false,
                    "markClean":true,
                ]);
                myResult[$locale] = $translation;
            }

            myOptions = ["setter":false, "guard":false];
            $row.set("_translations", myResult, myOptions);
            unset($row["_i18n"]);
            $row.clean();

            return $row;
        });
    }

    /**
     * Helper method used to generated multiple translated field entities
     * out of the data found in the `_translations` property in the passed
     * entity. The result will be put into its `_i18n` property.
     *
     * @param \Cake\Datasource\IEntity $entity Entity
     * @return void
     */
    protected auto bundleTranslatedFields($entity) {
        $translations = (array)$entity.get("_translations");

        if (empty($translations) && !$entity.isDirty("_translations")) {
            return;
        }

        myFields = _config["fields"];
        $primaryKey = (array)this.table.getPrimaryKey();
        myKey = $entity.get(current($primaryKey));
        $find = [];
        myContentss = [];

        foreach ($translations as $lang: $translation) {
            foreach (myFields as myField) {
                if (!$translation.isDirty(myField)) {
                    continue;
                }
                $find[] = ["locale":$lang, "field":myField, "foreign_key IS":myKey];
                myContentss[] = new Entity(["content":$translation.get(myField)], [
                    "useSetters":false,
                ]);
            }
        }

        if (empty($find)) {
            return;
        }

        myResults = this.findExistingTranslations($find);

        foreach ($find as $i: $translation) {
            if (!empty(myResults[$i])) {
                myContentss[$i].set("id", myResults[$i], ["setter":false]);
                myContentss[$i].setNew(false);
            } else {
                $translation["model"] = _config["referenceName"];
                myContentss[$i].set($translation, ["setter":false, "guard":false]);
                myContentss[$i].setNew(true);
            }
        }

        $entity.set("_i18n", myContentss);
    }

    /**
     * Returns the ids found for each of the condition arrays passed for the
     * translations table. Each records is indexed by the corresponding position
     * to the conditions array.
     *
     * @param array $ruleSet An array of array of conditions to be used for finding each
     * @return array
     */
    protected auto findExistingTranslations($ruleSet) {
        $association = this.table.getAssociation(this.translationTable.getAlias());

        myQuery = $association.find()
            .select(["id", "num":0])
            .where(current($ruleSet))
            .disableHydration()
            .disableBufferedResults();

        unset($ruleSet[0]);
        foreach ($ruleSet as $i: $conditions) {
            $q = $association.find()
                .select(["id", "num":$i])
                .where($conditions);
            myQuery.unionAll($q);
        }

        return myQuery.all().combine("num", "id").toArray();
    }
}
