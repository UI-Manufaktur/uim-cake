


 *



 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Mailer;

import uim.cake.View\View;
import uim.cake.View\ViewVarsTrait;

/**
 * Class for rendering email message.
 */
class Renderer
{
    use ViewVarsTrait;

    /**
     * Constant for folder name containing email templates.
     *
     * @var string
     */
    public const TEMPLATE_FOLDER = "email";

    /**
     * Constructor
     */
    public this() {
        this.reset();
    }

    /**
     * Render text/HTML content.
     *
     * If there is no template set, the $content will be returned in a hash
     * of the specified content types for the email.
     *
     * @param string $content The content.
     * @param array<string> $types Content types to render. Valid array values are Message::MESSAGE_HTML, Message::MESSAGE_TEXT.
     * @return array<string, string> The rendered content with "html" and/or "text" keys.
     * @psalm-param array<\Cake\Mailer\Message::MESSAGE_HTML|\Cake\Mailer\Message::MESSAGE_TEXT> $types
     * @psalm-return array{html?: string, text?: string}
     */
    function render(string $content, array $types = []): array
    {
        $rendered = [];
        $template = this.viewBuilder().getTemplate();
        if (empty($template)) {
            foreach ($types as $type) {
                $rendered[$type] = $content;
            }

            return $rendered;
        }

        $view = this.createView();

        [$templatePlugin] = pluginSplit($view.getTemplate());
        [$layoutPlugin] = pluginSplit($view.getLayout());
        if ($templatePlugin) {
            $view.setPlugin($templatePlugin);
        } elseif ($layoutPlugin) {
            $view.setPlugin($layoutPlugin);
        }

        if ($view.get("content") == null) {
            $view.set("content", $content);
        }

        foreach ($types as $type) {
            $view.setTemplatePath(static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . $type);
            $view.setLayoutPath(static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . $type);

            $rendered[$type] = $view.render();
        }

        return $rendered;
    }

    /**
     * Reset view builder to defaults.
     *
     * @return this
     */
    function reset() {
        _viewBuilder = null;

        this.viewBuilder()
            .setClassName(View::class)
            .setLayout("default")
            .setHelpers(["Html"], false);

        return this;
    }

    /**
     * Clone ViewBuilder instance when renderer is cloned.
     *
     * @return void
     */
    function __clone() {
        if (_viewBuilder != null) {
            _viewBuilder = clone _viewBuilder;
        }
    }
}
