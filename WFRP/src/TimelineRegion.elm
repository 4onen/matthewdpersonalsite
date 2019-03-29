module TimelineRegion exposing
    ( Date
    , RegionType(..)
    , TimelineRegion
    , compare
    , compareDates
    , dateExtents
    , dateToFloat
    , floatExtents
    , listFromSheet
    , toTimeRegionString
    )

import Dict exposing (Dict)
import Html


type alias Described a =
    { a | headline : String, text : Maybe String }


type alias Date =
    { year : Int
    , month : Maybe Int
    , day : Maybe Int
    , time : Maybe Int
    }


type RegionType
    = Region Date
    | Era Date
    | Point


type alias TimelineRegion =
    Described { start : Date, end : RegionType }


listFromSheet : List (Dict String String) -> Result (List String) (List TimelineRegion)
listFromSheet =
    List.filter (\r -> Dict.get "type" r /= Just "title")
        >> List.foldl
            (\i o ->
                case ( fromRow i, o ) of
                    ( Err err, Err errlist ) ->
                        Err <| ("Row #: " ++ err) :: errlist

                    ( Err err, _ ) ->
                        Err [ "Row #: " ++ err ]

                    ( Ok _, Err errlist ) ->
                        Err errlist

                    ( Ok dat, Ok datlist ) ->
                        Ok <| dat :: datlist
            )
            (Result.Ok [])
        >> Result.map sort


sort : List TimelineRegion -> List TimelineRegion
sort =
    List.sortWith compare


fromRow : Dict String String -> Result String TimelineRegion
fromRow r =
    let
        getRowStartDate : Dict String String -> Result String Date
        getRowStartDate =
            getRowDateObj "year" "month" "day" "time"

        getRowEndDate : Dict String String -> Result String Date
        getRowEndDate =
            getRowDateObj "endyear" "endmonth" "endday" "endtime"

        getRowDateObj : String -> String -> String -> String -> Dict String String -> Result String Date
        getRowDateObj yearkey monthkey daykey timekey row =
            Dict.get yearkey row
                |> Result.fromMaybe "DateObj missing year"
                |> Result.andThen (String.toInt >> Result.fromMaybe "DateObj year not an integer!")
                |> Result.map
                    (\year ->
                        Date
                            year
                            (Dict.get monthkey r |> Maybe.andThen String.toInt)
                            (Dict.get daykey r |> Maybe.andThen String.toInt)
                            (Dict.get timekey r |> Maybe.andThen String.toInt)
                    )

        splitMilitary : Int -> ( Int, Int )
        splitMilitary i =
            ( i // 100, modBy 100 i )
    in
    Result.map2
        (\headline date ->
            { headline = headline
            , text = Dict.get "text" r
            , start = date
            , end =
                case getRowEndDate r of
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
        (getRowStartDate r)


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


compareDates : Date -> Date -> Basics.Order
compareDates a b =
    let
        compyear =
            Basics.compare a.year b.year
    in
    if compyear /= EQ then
        compyear

    else
        let
            compmonth =
                compareMaybes a.month b.month
        in
        if compmonth /= EQ then
            compmonth

        else
            compareMaybes a.day b.day


compare : TimelineRegion -> TimelineRegion -> Basics.Order
compare a b =
    let
        compstart =
            compareDates a.start b.start
    in
    if compstart /= EQ then
        compstart

    else
        case ( a.end, b.end ) of
            ( Point, Point ) ->
                EQ

            ( Point, _ ) ->
                GT

            ( _, Point ) ->
                LT

            ( Region ea, Region eb ) ->
                compareDates ea eb

            ( Era ea, Era eb ) ->
                compareDates ea eb

            ( Era _, _ ) ->
                LT

            ( _, Era _ ) ->
                GT


getEnd : TimelineRegion -> Maybe Date
getEnd r =
    case r.end of
        Region date ->
            Just date

        Era date ->
            Just date

        Point ->
            Nothing


dateExtents : TimelineRegion -> ( Date, Date )
dateExtents r =
    ( r.start, getEnd r |> Maybe.withDefault r.start )


floatExtents : TimelineRegion -> ( Float, Float )
floatExtents r =
    let
        begin =
            dateToFloat True r.start

        end =
            getEnd r |> Maybe.map (dateToFloat False)
    in
    ( begin, Maybe.withDefault begin end )


dateToFloat : Bool -> Date -> Float
dateToFloat roundBegin d =
    let
        defaultDay =
            if roundBegin then
                1

            else
                31

        defaultMonth =
            if roundBegin then
                1

            else
                12
    in
    toFloat d.year
        + toFloat ((d.month |> Maybe.withDefault defaultMonth) - 1)
        / 12.0
        + toFloat ((d.day |> Maybe.withDefault defaultDay) - 1)
        / (31.0 * 12.0)


toTimeRegionString : TimelineRegion -> String
toTimeRegionString r =
    let
        startDateString =
            dateString r.start

        maybeEndString =
            getEnd r
                |> Maybe.map dateString
    in
    case maybeEndString of
        Just endDateString ->
            startDateString ++ " - " ++ endDateString

        Nothing ->
            startDateString


dateString : Date -> String
dateString date =
    (case ( monthString date, dayString date ) of
        ( Just monthName, Just dayName ) ->
            monthName ++ " " ++ dayName ++ ", " ++ String.fromInt date.year

        ( Just monthName, Nothing ) ->
            monthName ++ " " ++ String.fromInt date.year

        ( Nothing, _ ) ->
            String.fromInt date.year
    )
        |> (\dateName ->
            case timeString date of
                Just timeName ->
                    timeName ++ " on "++dateName

                Nothing ->
                    dateName
           )


monthString : Date -> Maybe String
monthString date =
    case date.month of
        Just 1 ->
            Just "January"

        Just 2 ->
            Just "February"

        Just 3 ->
            Just "March"

        Just 4 ->
            Just "April"

        Just 5 ->
            Just "May"

        Just 6 ->
            Just "June"

        Just 7 ->
            Just "July"

        Just 8 ->
            Just "August"

        Just 9 ->
            Just "September"

        Just 10 ->
            Just "October"

        Just 11 ->
            Just "November"

        Just 12 ->
            Just "December"

        _ ->
            Nothing


dayString : Date -> Maybe String
dayString =
    .day
        >> Maybe.map
            (\day ->
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
            )


timeString : Date -> Maybe String
timeString =
    .time
        >> Maybe.map
            (\time ->
                case time of
                    1200 ->
                        "12:00pm"

                    0 ->
                        "00:00am"

                    _ ->
                        let
                            hour =
                                time // 100

                            minute =
                                modBy 100 time

                            pm =
                                time > 12

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
            )
