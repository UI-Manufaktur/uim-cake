module uim.cake.views;

@safe:
import uim.cake;

/**
 * Adds string template functionality to any class by providing methods to
 * load and parse string templates.
 *
 * This trait requires the implementing class to provide a `config()`
 * method for reading/updating templates. An implementation of this method
 * is provided by `Cake\Core\InstanceConfigTrait`
 */
trait StringTemplateTrait
{
    /**
     * StringTemplate instance.
     *
     * @var uim.cake.View\StringTemplate|null
     */
    protected _templater;

    /**
     * Sets templates to use.
     *
     * @param array<string> myTemplates Templates to be added.
     * @return this
     */
    auto setTemplates(array myTemplates) {
        this.templater().add(myTemplates);

        return this;
    }

    /**
     * Gets templates to use or a specific template.
     *
     * @param string|null myTemplate String for reading a specific template, null for all.
     * @return array|string
     */
    auto getTemplates(Nullable!string myTemplate = null) {
        return this.templater().get(myTemplate);
    }

    /**
     * Formats a template string with myData
     *
     * @param string myName The template name.
     * @param array<string, mixed> myData The data to insert.
     * @return string
     */
    string formatTemplate(string myName, array myData) {
        return this.templater().format(myName, myData);
    }

    /**
     * Returns the templater instance.
     *
     * @return uim.cake.View\StringTemplate
     */
    function templater(): StringTemplate
    {
        if (_templater is null) {
            /** @var class-string<\Cake\View\StringTemplate> myClass */
            myClass = this.getConfig("templateClass") ?: StringTemplate::class;
            _templater = new myClass();

            myTemplates = this.getConfig("templates");
            if (myTemplates) {
                if (is_string(myTemplates)) {
                    _templater.add(_defaultConfig["templates"]);
                    _templater.load(myTemplates);
                } else {
                    _templater.add(myTemplates);
                }
            }
        }

        return _templater;
    }
}
