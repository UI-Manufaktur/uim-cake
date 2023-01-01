module uim.cake.orm.Behavior\Translate;

import uim.cake.datasources.IEntity;

/**
 * Contains a translation method aimed to help managing multiple translations
 * for an entity.
 */
trait TranslateTrait
{
    /**
     * Returns the entity containing the translated fields for this object and for
     * the specified language. If the translation for the passed language is not
     * present, a new empty entity will be created so that values can be added to
     * it.
     *
     * @param string $language Language to return entity for.
     * @return uim.cake.Datasource\IEntity|this
     */
    function translation(string $language) {
        if ($language == this.get("_locale")) {
            return this;
        }

        $i18n = this.get("_translations");
        $created = false;

        if (empty($i18n)) {
            $i18n = [];
            $created = true;
        }

        if ($created || empty($i18n[$language]) || !($i18n[$language] instanceof IEntity)) {
            $className = static::class;

            $i18n[$language] = new $className();
            $created = true;
        }

        if ($created) {
            this.set("_translations", $i18n);
        }

        // Assume the user will modify any of the internal translations, helps with saving
        this.setDirty("_translations", true);

        return $i18n[$language];
    }
}
