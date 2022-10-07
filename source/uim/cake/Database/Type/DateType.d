module uim.cake.database.Type;

import uim.cake.I18n\Date;
import uim.cake.I18n\FrozenDate;
import uim.cake.I18n\I18nIDateTime;
use DateTime;
use DateTimeImmutable;
use IDateTime;

/**
 * Class DateType
 */
class DateType : DateTimeType
{

    protected $_format = 'Y-m-d';


    protected $_marshalFormats = [
        'Y-m-d',
    ];

    /**
     * In this class we want Date objects to  have their time
     * set to the beginning of the day.
     *
     * @var bool
     */
    protected $setToDateStart = true;


    this(?string myName = null)
    {
        super.this(myName);

        this._setClassName(FrozenDate::class, DateTimeImmutable::class);
    }

    /**
     * Change the preferred class name to the FrozenDate implementation.
     *
     * @return this
     * @deprecated 4.3.0 This method is no longer needed as using immutable datetime class is the default behavior.
     */
    function useImmutable() {
        deprecationWarning(
            'Configuring immutable or mutable classes is deprecated and immutable'
            . ' classes will be the permanent configuration in 5.0. Calling `useImmutable()` is unnecessary.'
        );

        this._setClassName(FrozenDate::class, DateTimeImmutable::class);

        return this;
    }

    /**
     * Change the preferred class name to the mutable Date implementation.
     *
     * @return this
     * @deprecated 4.3.0 Using mutable datetime objects is deprecated.
     */
    function useMutable() {
        deprecationWarning(
            'Configuring immutable or mutable classes is deprecated and immutable'
            . ' classes will be the permanent configuration in 5.0. Calling `useImmutable()` is unnecessary.'
        );

        this._setClassName(Date::class, DateTime::class);

        return this;
    }

    /**
     * Convert request data into a datetime object.
     *
     * @param mixed myValue Request data
     * @return \IDateTime|null
     */
    function marshal(myValue): ?IDateTime
    {
        $date = super.marshal(myValue);
        /** @psalm-var \DateTime|\DateTimeImmutable|null $date */
        if ($date && !$date instanceof I18nIDateTime) {
            // Clear time manually when I18n types aren't available and raw DateTime used
            $date = $date.setTime(0, 0, 0);
        }

        return $date;
    }


    protected auto _parseLocaleValue(string myValue): ?I18nIDateTime
    {
        /** @psalm-var class-string<\Cake\I18n\I18nIDateTime> myClass */
        myClass = this._className;

        return myClass::parseDate(myValue, this._localeMarshalFormat);
    }
}
