module uim.cake.Mailer;

import uim.cake.views\View;
import uim.cake.views\ViewVarsTrait;

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
    public const TEMPLATE_FOLDER = 'email';

    /**
     * Constructor
     */
    this() {
        this.reset();
    }

    /**
     * Render text/HTML content.
     *
     * If there is no template set, the myContents will be returned in a hash
     * of the specified content types for the email.
     *
     * @param string myContents The content.
     * @param array<string> myTypes Content types to render. Valid array values are Message::MESSAGE_HTML, Message::MESSAGE_TEXT.
     * @return array<string, string> The rendered content with "html" and/or "text" keys.
     * @psalm-param array<\Cake\Mailer\Message::MESSAGE_HTML|\Cake\Mailer\Message::MESSAGE_TEXT> myTypes
     * @psalm-return array{html?: string, text?: string}
     */
    function render(string myContents, array myTypes = []): array
    {
        $rendered = [];
        myTemplate = this.viewBuilder().getTemplate();
        if (empty(myTemplate)) {
            foreach (myTypes as myType) {
                $rendered[myType] = myContents;
            }

            return $rendered;
        }

        $view = this.createView();

        [myTemplatePlugin] = pluginSplit($view.getTemplate());
        [$layoutPlugin] = pluginSplit($view.getLayout());
        if (myTemplatePlugin) {
            $view.setPlugin(myTemplatePlugin);
        } elseif ($layoutPlugin) {
            $view.setPlugin($layoutPlugin);
        }

        if ($view.get('content') === null) {
            $view.set('content', myContents);
        }

        foreach (myTypes as myType) {
            $view.setTemplatePath(static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . myType);
            $view.setLayoutPath(static::TEMPLATE_FOLDER . DIRECTORY_SEPARATOR . myType);

            $rendered[myType] = $view.render();
        }

        return $rendered;
    }

    /**
     * Reset view builder to defaults.
     *
     * @return this
     */
    function reset() {
        this._viewBuilder = null;

        this.viewBuilder()
            .setClassName(View::class)
            .setLayout('default')
            .setHelpers(['Html'], false);

        return this;
    }

    /**
     * Clone ViewBuilder instance when renderer is cloned.
     *
     * @return void
     */
    auto __clone() {
        if (this._viewBuilder !== null) {
            this._viewBuilder = clone this._viewBuilder;
        }
    }
}
