

/**
 * CakePHP(tm) : Rapid Development Framework (https://cakephp.org)
 * Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 *
 * Licensed under The MIT License
 * For full copyright and license information, please see the LICENSE.txt
 * Redistributions of files must retain the above copyright notice.
 *
 * @copyright     Copyright (c) Cake Software Foundation, Inc. (https://cakefoundation.org)
 * @link          https://cakephp.org CakePHP(tm) Project
 * @since         0.10.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.View\Helper;

import uim.cake.Core\App;
import uim.cake.Core\Exception\CakeException;
import uim.cake.Utility\Security;
import uim.cake.Utility\Text;
import uim.cake.View\Helper;
import uim.cake.View\View;

/**
 * Text helper library.
 *
 * Text manipulations: Highlight, excerpt, truncate, strip of links, convert email addresses to mailto: links...
 *
 * @property \Cake\View\Helper\HtmlHelper $Html
 * @link https://book.cakephp.org/4/en/views/helpers/text.html
 * @see \Cake\Utility\Text
 */
class TextHelper : Helper
{
    /**
     * helpers
     *
     * @var array
     */
    protected $helpers = ['Html'];

    /**
     * Default config for this class
     *
     * @var array<string, mixed>
     */
    protected $_defaultConfig = [
        'engine': Text::class,
    ];

    /**
     * An array of hashes and their contents.
     * Used when inserting links into text.
     *
     * @var array<string, array>
     */
    protected $_placeholders = [];

    /**
     * Cake Utility Text instance
     *
     * @var \Cake\Utility\Text
     */
    protected $_engine;

    /**
     * Constructor
     *
     * ### Settings:
     *
     * - `engine` Class name to use to replace String functionality.
     *            The class needs to be placed in the `Utility` directory.
     *
     * @param \Cake\View\View $view the view object the helper is attached to.
     * @param array<string, mixed> $config Settings array Settings array
     * @throws \Cake\Core\Exception\CakeException when the engine class could not be found.
     */
    public this(View $view, array $config = [])
    {
        parent::__construct($view, $config);

        $config = _config;

        /** @psalm-var class-string<\Cake\Utility\Text>|null $engineClass */
        $engineClass = App::className($config['engine'], 'Utility');
        if ($engineClass == null) {
            throw new CakeException(sprintf('Class for %s could not be found', $config['engine']));
        }

        _engine = new $engineClass($config);
    }

    /**
     * Call methods from String utility class
     *
     * @param string $method Method to invoke
     * @param array $params Array of params for the method.
     * @return mixed Whatever is returned by called method, or false on failure
     */
    function __call(string $method, array $params)
    {
        return _engine.{$method}(...$params);
    }

    /**
     * Adds links (<a href=....) to a given text, by finding text that begins with
     * strings like http:// and ftp://.
     *
     * ### Options
     *
     * - `escape` Control HTML escaping of input. Defaults to true.
     *
     * @param string $text Text
     * @param array<string, mixed> $options Array of HTML options, and options listed above.
     * @return string The text with links
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#linking-urls
     */
    function autoLinkUrls(string $text, array $options = []): string
    {
        _placeholders = [];
        $options += ['escape': true];

        // phpcs:disable Generic.Files.LineLength
        $pattern = '/(?:(?<!href="|src="|">)
            (?>
                (
                    (?<left>[\[<(]) # left paren,brace
                    (?>
                        # Lax match URL
                        (?<url>(?:https?|ftp|nntp):\/\/[\p{L}0-9.\-_:]+(?:[\/?][\p{L}0-9.\-_:\/?=&>\[\]\(\)\#\@\+~!;,%]+[^-_:?>\[\(\@\+~!;<,.%\s])?)
                        (?<right>[\])>]) # right paren,brace
                    )
                )
                |
                (?<url_bare>(?P>url)) # A bare URL. Use subroutine
            )
            )/ixu';
        // phpcs:enable Generic.Files.LineLength

        $text = preg_replace_callback(
            $pattern,
            [&this, '_insertPlaceHolder'],
            $text
        );
        // phpcs:disable Generic.Files.LineLength
        $text = preg_replace_callback(
            '#(?<!href="|">)(?<!\b[[:punct:]])(?<!http://|https://|ftp://|nntp://)www\.[^\s\n\%\ <]+[^\s<\n\%\,\.\ ](?<!\))#i',
            [&this, '_insertPlaceHolder'],
            $text
        );
        // phpcs:enable Generic.Files.LineLength
        if ($options['escape']) {
            $text = h($text);
        }

        return _linkUrls($text, $options);
    }

    /**
     * Saves the placeholder for a string, for later use. This gets around double
     * escaping content in URL's.
     *
     * @param array $matches An array of regexp matches.
     * @return string Replaced values.
     */
    protected function _insertPlaceHolder(array $matches): string
    {
        $match = $matches[0];
        $envelope = ['', ''];
        if (isset($matches['url'])) {
            $match = $matches['url'];
            $envelope = [$matches['left'], $matches['right']];
        }
        if (isset($matches['url_bare'])) {
            $match = $matches['url_bare'];
        }
        $key = hash_hmac('sha1', $match, Security::getSalt());
        _placeholders[$key] = [
            'content': $match,
            'envelope': $envelope,
        ];

        return $key;
    }

    /**
     * Replace placeholders with links.
     *
     * @param string $text The text to operate on.
     * @param array<string, mixed> $htmlOptions The options for the generated links.
     * @return string The text with links inserted.
     */
    protected function _linkUrls(string $text, array $htmlOptions): string
    {
        $replace = [];
        foreach (_placeholders as $hash: $content) {
            $link = $url = $content['content'];
            $envelope = $content['envelope'];
            if (!preg_match('#^[a-z]+\://#i', $url)) {
                $url = 'http://' . $url;
            }
            $replace[$hash] = $envelope[0] . this.Html.link($link, $url, $htmlOptions) . $envelope[1];
        }

        return strtr($text, $replace);
    }

    /**
     * Links email addresses
     *
     * @param string $text The text to operate on
     * @param array<string, mixed> $options An array of options to use for the HTML.
     * @return string
     * @see \Cake\View\Helper\TextHelper::autoLinkEmails()
     */
    protected function _linkEmails(string $text, array $options): string
    {
        $replace = [];
        foreach (_placeholders as $hash: $content) {
            $url = $content['content'];
            $envelope = $content['envelope'];
            $replace[$hash] = $envelope[0] . this.Html.link($url, 'mailto:' . $url, $options) . $envelope[1];
        }

        return strtr($text, $replace);
    }

    /**
     * Adds email links (<a href="mailto:....") to a given text.
     *
     * ### Options
     *
     * - `escape` Control HTML escaping of input. Defaults to true.
     *
     * @param string $text Text
     * @param array<string, mixed> $options Array of HTML options, and options listed above.
     * @return string The text with links
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#linking-email-addresses
     */
    function autoLinkEmails(string $text, array $options = []): string
    {
        $options += ['escape': true];
        _placeholders = [];

        $atom = '[\p{L}0-9!#$%&\'*+\/=?^_`{|}~-]';
        $text = preg_replace_callback(
            '/(?<=\s|^|\(|\>|\;)(' . $atom . '*(?:\.' . $atom . '+)*@[\p{L}0-9-]+(?:\.[\p{L}0-9-]+)+)/ui',
            [&this, '_insertPlaceholder'],
            $text
        );
        if ($options['escape']) {
            $text = h($text);
        }

        return _linkEmails($text, $options);
    }

    /**
     * Convert all links and email addresses to HTML links.
     *
     * ### Options
     *
     * - `escape` Control HTML escaping of input. Defaults to true.
     *
     * @param string $text Text
     * @param array<string, mixed> $options Array of HTML options, and options listed above.
     * @return string The text with links
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#linking-both-urls-and-email-addresses
     */
    function autoLink(string $text, array $options = []): string
    {
        $text = this.autoLinkUrls($text, $options);

        return this.autoLinkEmails($text, ['escape': false] + $options);
    }

    /**
     * Highlights a given phrase in a text. You can specify any expression in highlighter that
     * may include the \1 expression to include the $phrase found.
     *
     * @param string $text Text to search the phrase in
     * @param string $phrase The phrase that will be searched
     * @param array<string, mixed> $options An array of HTML attributes and options.
     * @return string The highlighted text
     * @see \Cake\Utility\Text::highlight()
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#highlighting-substrings
     */
    function highlight(string $text, string $phrase, array $options = []): string
    {
        return _engine.highlight($text, $phrase, $options);
    }

    /**
     * Formats paragraphs around given text for all line breaks
     *  <br /> added for single line return
     *  <p> added for double line return
     *
     * @param string|null $text Text
     * @return string The text with proper <p> and <br /> tags
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#converting-text-into-paragraphs
     */
    function autoParagraph(?string $text): string
    {
        $text = $text ?? '';
        if (trim($text) != '') {
            $text = preg_replace('|<br[^>]*>\s*<br[^>]*>|i', "\n\n", $text . "\n");
            $text = preg_replace("/\n\n+/", "\n\n", str_replace(["\r\n", "\r"], "\n", $text));
            $texts = preg_split('/\n\s*\n/', $text, -1, PREG_SPLIT_NO_EMPTY);
            $text = '';
            foreach ($texts as $txt) {
                $text .= '<p>' . nl2br(trim($txt, "\n")) . "</p>\n";
            }
            $text = preg_replace('|<p>\s*</p>|', '', $text);
        }

        return $text;
    }

    /**
     * Truncates text.
     *
     * Cuts a string to the length of $length and replaces the last characters
     * with the ellipsis if the text is longer than length.
     *
     * ### Options:
     *
     * - `ellipsis` Will be used as Ending and appended to the trimmed string
     * - `exact` If false, $text will not be cut mid-word
     * - `html` If true, HTML tags would be handled correctly
     *
     * @param string $text String to truncate.
     * @param int $length Length of returned string, including ellipsis.
     * @param array<string, mixed> $options An array of HTML attributes and options.
     * @return string Trimmed string.
     * @see \Cake\Utility\Text::truncate()
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#truncating-text
     */
    function truncate(string $text, int $length = 100, array $options = []): string
    {
        return _engine.truncate($text, $length, $options);
    }

    /**
     * Truncates text starting from the end.
     *
     * Cuts a string to the length of $length and replaces the first characters
     * with the ellipsis if the text is longer than length.
     *
     * ### Options:
     *
     * - `ellipsis` Will be used as Beginning and prepended to the trimmed string
     * - `exact` If false, $text will not be cut mid-word
     *
     * @param string $text String to truncate.
     * @param int $length Length of returned string, including ellipsis.
     * @param array<string, mixed> $options An array of HTML attributes and options.
     * @return string Trimmed string.
     * @see \Cake\Utility\Text::tail()
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#truncating-the-tail-of-a-string
     */
    function tail(string $text, int $length = 100, array $options = []): string
    {
        return _engine.tail($text, $length, $options);
    }

    /**
     * Extracts an excerpt from the text surrounding the phrase with a number of characters on each side
     * determined by radius.
     *
     * @param string $text String to search the phrase in
     * @param string $phrase Phrase that will be searched for
     * @param int $radius The amount of characters that will be returned on each side of the founded phrase
     * @param string $ending Ending that will be appended
     * @return string Modified string
     * @see \Cake\Utility\Text::excerpt()
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#extracting-an-excerpt
     */
    function excerpt(string $text, string $phrase, int $radius = 100, string $ending = '...'): string
    {
        return _engine.excerpt($text, $phrase, $radius, $ending);
    }

    /**
     * Creates a comma separated list where the last two items are joined with 'and', forming natural language.
     *
     * @param array<string> $list The list to be joined.
     * @param string|null $and The word used to join the last and second last items together with. Defaults to 'and'.
     * @param string $separator The separator used to join all the other items together. Defaults to ', '.
     * @return string The glued together string.
     * @see \Cake\Utility\Text::toList()
     * @link https://book.cakephp.org/4/en/views/helpers/text.html#converting-an-array-to-sentence-form
     */
    function toList(array $list, ?string $and = null, string $separator = ', '): string
    {
        return _engine.toList($list, $and, $separator);
    }

    /**
     * Returns a string with all spaces converted to dashes (by default),
     * characters transliterated to ASCII characters, and non word characters removed.
     *
     * ### Options:
     *
     * - `replacement`: Replacement string. Default '-'.
     * - `transliteratorId`: A valid transliterator id string.
     *   If `null` (default) the transliterator (identifier) set via
     *   `Text::setTransliteratorId()` or `Text::setTransliterator()` will be used.
     *   If `false` no transliteration will be done, only non-words will be removed.
     * - `preserve`: Specific non-word character to preserve. Default `null`.
     *   For e.g. this option can be set to '.' to generate clean file names.
     *
     * @param string $string the string you want to slug
     * @param array<string, mixed>|string $options If string it will be used as replacement character
     *   or an array of options.
     * @return string
     * @see \Cake\Utility\Text::setTransliterator()
     * @see \Cake\Utility\Text::setTransliteratorId()
     */
    function slug(string $string, $options = []): string
    {
        return _engine.slug($string, $options);
    }

    /**
     * Event listeners.
     *
     * @return array<string, mixed>
     */
    function implementedEvents(): array
    {
        return [];
    }
}
