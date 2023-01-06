module uim.cake.View;

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
     * @param array<string> $templates Templates to be added.
     * @return this
     */
    function setTemplates(array $templates) {
        this.templater().add($templates);

        return this;
    }

    /**
     * Gets templates to use or a specific template.
     *
     * @param string|null $template String for reading a specific template, null for all.
     * @return array|string
     */
    function getTemplates(Nullable!string $template = null) {
        return this.templater().get($template);
    }

    /**
     * Formats a template string with $data
     *
     * @param string aName The template name.
     * @param array<string, mixed> $data The data to insert.
     */
    string formatTemplate(string aName, array $data) {
        return this.templater().format($name, $data);
    }

    /**
     * Returns the templater instance.
     *
     * @return uim.cake.View\StringTemplate
     */
    StringTemplate templater() {
        if (_templater == null) {
            /** @var class-string<uim.cake.View\StringTemplate> $class */
            $class = this.getConfig("templateClass") ?: StringTemplate::class;
            _templater = new $class();

            $templates = this.getConfig("templates");
            if ($templates) {
                if (is_string($templates)) {
                    _templater.add(_defaultConfig["templates"]);
                    _templater.load($templates);
                } else {
                    _templater.add($templates);
                }
            }
        }

        return _templater;
    }
}
