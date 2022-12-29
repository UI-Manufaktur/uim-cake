


 *


 * @since         3.1.0
 * @license       https://opensource.org/licenses/mit-license.php MIT License
 */
module uim.cake.Mailer;

import uim.cake.core.App;
import uim.cake.Mailer\Exception\MissingMailerException;

/**
 * Provides functionality for loading mailer classes
 * onto properties of the host object.
 *
 * Example users of this trait are Cake\Controller\Controller and
 * Cake\Console\Command.
 */
trait MailerAwareTrait
{
    /**
     * Returns a mailer instance.
     *
     * @param string $name Mailer"s name.
     * @param array<string, mixed>|string|null $config Array of configs, or profile name string.
     * @return uim.cake.Mailer\Mailer
     * @throws uim.cake.Mailer\Exception\MissingMailerException if undefined mailer class.
     */
    protected function getMailer(string $name, $config = null): Mailer
    {
        $className = App::className($name, "Mailer", "Mailer");
        if ($className == null) {
            throw new MissingMailerException(compact("name"));
        }

        return new $className($config);
    }
}
