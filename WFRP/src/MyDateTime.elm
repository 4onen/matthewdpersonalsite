module MyDateTime exposing
    ( Accuracy(..)
    , DateTime(..)
    , compare
    , from
    , getDate
    , getDateTime
    , getDay
    , getMonth
    , getTime
    , getYear
    , toMillis
    , toPosix
    )

import Calendar
import Clock
import DateTime
import Time


type Accuracy
    = Year
    | Month
    | Day
    | Time


type DateTime
    = DateTime
        { acc : Accuracy
        , date : DateTime.DateTime
        }


from : Int -> Maybe Time.Month -> Maybe Int -> Maybe Clock.Time -> Maybe DateTime
from year month day maybeTime =
    let
        date =
            Calendar.fromRawParts
                { year = year
                , month = Maybe.withDefault Time.Jan month
                , day = Maybe.withDefault 1 day
                }

        time =
            Maybe.withDefault Clock.midnight maybeTime

        acc =
            case ( month, day, maybeTime ) of
                ( Just _, Just _, Just _ ) ->
                    Time

                ( Just _, Just _, _ ) ->
                    Day

                ( Just _, _, _ ) ->
                    Month

                _ ->
                    Year
    in
    case date of
        Just d ->
            Just <|
                DateTime
                    { date = DateTime.fromDateAndTime d time
                    , acc = acc
                    }

        Nothing ->
            Nothing


toPosix : DateTime -> Time.Posix
toPosix (DateTime { date }) =
    DateTime.toPosix date


toMillis : DateTime -> Int
toMillis =
    toPosix >> Time.posixToMillis


getYear : DateTime -> Int
getYear (DateTime { date }) =
    DateTime.getYear date


getMonth : DateTime -> Maybe Time.Month
getMonth (DateTime { acc, date }) =
    case acc of
        Time ->
            Just (DateTime.getMonth date)

        Day ->
            Just (DateTime.getMonth date)

        Month ->
            Just (DateTime.getMonth date)

        Year ->
            Nothing


getDay : DateTime -> Maybe Int
getDay (DateTime { acc, date }) =
    case acc of
        Time ->
            Just (DateTime.getDay date)

        Day ->
            Just (DateTime.getDay date)

        _ ->
            Nothing


getDateTime : DateTime -> DateTime.DateTime
getDateTime (DateTime { date }) =
    date


getDate : DateTime -> Calendar.Date
getDate (DateTime { date }) =
    DateTime.getDate date


getTime : DateTime -> Maybe Clock.Time
getTime (DateTime { acc, date }) =
    case acc of
        Time ->
            Just (DateTime.getTime date)

        _ ->
            Nothing


compare : DateTime -> DateTime -> Basics.Order
compare (DateTime a) (DateTime b) =
    DateTime.compare a.date b.date
