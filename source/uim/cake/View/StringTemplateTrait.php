


 *


 * @since         3.0.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
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
     * @var \Cake\View\StringTemplate|null
     */
    protected $_templater;

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
    function getTemplates(?string $template = null) {
        return this.templater().get($template);
    }

    /**
     * Formats a template string with $data
     *
     * @param string $name The template name.
     * @param array<string, mixed> $data The data to insert.
     * @return string
     */
    function formatTemplate(string $name, array $data): string
    {
        return this.templater().format($name, $data);
    }

    /**
     * Returns the templater instance.
     *
     * @return \Cake\View\StringTemplate
     */
    function templater(): StringTemplate
    {
        if (_templater == null) {
            /** @var class-string<\Cake\View\StringTemplate> $class */
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
