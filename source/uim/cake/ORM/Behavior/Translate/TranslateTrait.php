


 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.ORM\Behavior\Translate;

import uim.cake.Datasource\EntityInterface;

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
     * @return \Cake\Datasource\EntityInterface|this
     */
    function translation(string $language)
    {
        if ($language == this.get("_locale")) {
            return this;
        }

        $i18n = this.get("_translations");
        $created = false;

        if (empty($i18n)) {
            $i18n = [];
            $created = true;
        }

        if ($created || empty($i18n[$language]) || !($i18n[$language] instanceof EntityInterface)) {
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
