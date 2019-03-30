module TimelineRegion exposing
    ( RegionType(..)
    , TimelineRegion
    , dateExtents
    , listFromSheet
    , toTimeRangeString
    )

import Calendar
import Clock
import DateTime
import Dict exposing (Dict)
import Html
import MyDateTime exposing (DateTime)
import Time


type alias Described a =
    { a | headline : String, text : Maybe String }


type RegionType
    = Region DateTime
    | Era DateTime
    | Point


type alias TimelineRegion =
    Described { start : DateTime, end : RegionType }


listFromSheet : List (Dict String String) -> Result (List String) (List TimelineRegion)
listFromSheet =
    List.indexedMap Tuple.pair
        >> List.map (Tuple.mapFirst ((+) 2))
        >> List.filter (\( _, r ) -> Dict.get "type" r /= Just "title")
        >> List.foldl
            (\( i, r ) o ->
                case ( fromRow r, o ) of
                    ( Err err, Err errlist ) ->
                        Err <| ("Row " ++ String.fromInt i ++ ": " ++ err) :: errlist

                    ( Err err, _ ) ->
                        Err [ "Row " ++ String.fromInt i ++ ": " ++ err ]

                    ( Ok _, Err errlist ) ->
                        Err errlist

                    ( Ok dat, Ok datlist ) ->
                        Ok <| dat :: datlist
            )
            (Result.Ok [])
        >> Result.map (List.sortWith compare)


compare : TimelineRegion -> TimelineRegion -> Basics.Order
compare a b =
    let
        startcomp =
            MyDateTime.compare a.start b.start
    in
    if startcomp /= EQ then
        startcomp

    else
        case ( a.end, b.end ) of
            ( Region da, Region db ) ->
                MyDateTime.compare da db

            ( Era da, Era db ) ->
                MyDateTime.compare da db

            ( Era _, _ ) ->
                LT

            ( _, Era _ ) ->
                GT

            ( Point, Point ) ->
                EQ

            ( Point, _ ) ->
                LT

            ( _, Point ) ->
                GT


fromRow : Dict String String -> Result String TimelineRegion
fromRow r =
    let
        getRowStartDateTime : Dict String String -> Result String DateTime
        getRowStartDateTime =
            getRowDateTime "year" "month" "day" "time"

        getRowEndDateTime : Dict String String -> Result String DateTime
        getRowEndDateTime =
            getRowDateTime "endyear" "endmonth" "endday" "endtime"

        getRowDateTime : String -> String -> String -> String -> Dict String String -> Result String DateTime
        getRowDateTime yearkey monthkey daykey timekey row =
            let
                maybeTime =
                    getRowTime timekey row
            in
            row
                |> Dict.get yearkey
                |> Result.fromMaybe "Can't find year"
                |> Result.andThen (String.toInt >> Result.fromMaybe "Can't parse year -- not an integer")
                |> Result.andThen
                    (\year ->
                        MyDateTime.from year
                            (Dict.get monthkey row |> Maybe.andThen String.toInt |> Maybe.andThen monthFromInt)
                            (Dict.get daykey row |> Maybe.andThen String.toInt)
                            maybeTime
                            |> Result.fromMaybe ("Error forming date object for year " ++ String.fromInt year)
                    )

        getRowTime : String -> Dict String String -> Maybe Clock.Time
        getRowTime timekey =
            Dict.get timekey
                >> Maybe.andThen String.toInt
                >> Maybe.map
                    (\t ->
                        { hours = t // 100
                        , minutes = modBy 100 t
                        , seconds = 0
                        , milliseconds = 0
                        }
                    )
                >> Maybe.andThen Clock.fromRawParts
    in
    Result.map2
        (\headline date ->
            { headline = headline
            , text = Dict.get "text" r
            , start = date
            , end =
                case getRowEndDateTime r of
                    Ok enddate ->
                        case Dict.get "type" r of
                            Just "era" ->
                                Era enddate

                            _ ->
                                Region enddate

                    Err _ ->
                        Point
            }
        )
        (Dict.get "headline" r |> Result.fromMaybe "Row missing headline!")
        (getRowStartDateTime r)


compareMaybes : Maybe comparable -> Maybe comparable -> Basics.Order
compareMaybes =
    compareMaybesWith Basics.compare


compareMaybesWith : (a -> b -> Basics.Order) -> Maybe a -> Maybe b -> Basics.Order
compareMaybesWith f a b =
    case ( a, b ) of
        ( Just aval, Just bval ) ->
            f aval bval

        ( Nothing, Just bval ) ->
            Basics.LT

        ( Just aval, Nothing ) ->
            Basics.GT

        ( Nothing, Nothing ) ->
            Basics.EQ


getEnd : TimelineRegion -> Maybe DateTime
getEnd r =
    case r.end of
        Region date ->
            Just date

        Era date ->
            Just date

        Point ->
            Nothing


dateExtents : TimelineRegion -> ( DateTime, DateTime )
dateExtents r =
    ( r.start, getEnd r |> Maybe.withDefault r.start )


toTimeRangeString : TimelineRegion -> String
toTimeRangeString r =
    let
        startDateString =
            dateTimeString r.start

        maybeEndString =
            getEnd r
                |> Maybe.map dateTimeString
    in
    case maybeEndString of
        Just endDateString ->
            startDateString ++ " - " ++ endDateString

        Nothing ->
            startDateString


dateTimeString : DateTime -> String
dateTimeString date =
    (case
        ( Maybe.map monthToString <| MyDateTime.getMonth date
        , Maybe.map dayToString <| MyDateTime.getDay date
        )
     of
        ( Just monthName, Just dayName ) ->
            monthName ++ " " ++ dayName ++ ", " ++ String.fromInt (MyDateTime.getYear date)

        ( Just monthName, Nothing ) ->
            monthName ++ " " ++ String.fromInt (MyDateTime.getYear date)

        ( Nothing, _ ) ->
            String.fromInt (MyDateTime.getYear date)
    )
        |> (\dateName ->
                case Maybe.map timeToString <| MyDateTime.getTime date of
                    Just timeName ->
                        timeName ++ " on " ++ dateName

                    Nothing ->
                        dateName
           )


monthFromInt : Int -> Maybe Time.Month
monthFromInt m =
    case m of
        1 ->
            Just Time.Jan

        2 ->
            Just Time.Feb

        3 ->
            Just Time.Mar

        4 ->
            Just Time.Apr

        5 ->
            Just Time.May

        6 ->
            Just Time.Jun

        7 ->
            Just Time.Jul

        8 ->
            Just Time.Aug

        9 ->
            Just Time.Sep

        10 ->
            Just Time.Oct

        11 ->
            Just Time.Nov

        12 ->
            Just Time.Dec

        _ ->
            Nothing


monthToString : Time.Month -> String
monthToString month =
    case month of
        Time.Jan ->
            "January"

        Time.Feb ->
            "February"

        Time.Mar ->
            "March"

        Time.Apr ->
            "April"

        Time.May ->
            "May"

        Time.Jun ->
            "June"

        Time.Jul ->
            "July"

        Time.Aug ->
            "August"

        Time.Sep ->
            "September"

        Time.Oct ->
            "October"

        Time.Nov ->
            "November"

        Time.Dec ->
            "December"


dayToString : Int -> String
dayToString day =
    case day of
        1 ->
            "1st"

        2 ->
            "2nd"

        3 ->
            "3rd"

        21 ->
            "21st"

        22 ->
            "22nd"

        23 ->
            "23rd"

        31 ->
            "31st"

        n ->
            String.fromInt n ++ "th"


timeToString : Clock.Time -> String
timeToString time =
    let
        hour =
            Clock.getHours time

        minute =
            Clock.getMinutes time

        pm =
            hour > 12

        pmAppliedHour =
            if pm then
                hour - 12

            else
                hour
    in
    String.fromInt pmAppliedHour
        ++ ":"
        ++ String.fromInt minute
        ++ (if pm then
                "pm"

            else
                "am"
           )
