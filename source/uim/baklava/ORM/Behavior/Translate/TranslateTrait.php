module uim.baklava.orm.Behavior\Translate;

import uim.baklava.Datasource\IEntity;

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
     * @param string myLanguage Language to return entity for.
     * @return \Cake\Datasource\IEntity|this
     */
    function translation(string myLanguage) {
        if (myLanguage === this.get('_locale')) {
            return this;
        }

        $i18n = this.get('_translations');
        $created = false;

        if (empty($i18n)) {
            $i18n = [];
            $created = true;
        }

        if ($created || empty($i18n[myLanguage]) || !($i18n[myLanguage] instanceof IEntity)) {
            myClassName = static::class;

            $i18n[myLanguage] = new myClassName();
            $created = true;
        }

        if ($created) {
            this.set('_translations', $i18n);
        }

        // Assume the user will modify any of the internal translations, helps with saving
        this.setDirty('_translations', true);

        return $i18n[myLanguage];
    }
}
