module TimelineRegion exposing
    ( Date
    , RegionType(..)
    , TimelineRegion
    , compare
    , compareDates
    , listFromSheet
    , regionFloatExtents
    , view
    )

import Dict exposing (Dict)
import Html


type alias Described a =
    { a | headline : String, text : Maybe String }


type alias Date =
    { year : Int, month : Maybe Int, day : Maybe Int }


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
    Result.map2
        (\headline date ->
            { headline = headline
            , text = Dict.get "text" r
            , start = date
            , end =
                case getEndDate r of
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
        (getStartDate r)


getStartDate : Dict String String -> Result String Date
getStartDate =
    getDateObj "year" "month" "day"


getEndDate : Dict String String -> Result String Date
getEndDate =
    getDateObj "endyear" "endmonth" "endday"


getDateObj : String -> String -> String -> Dict String String -> Result String Date
getDateObj yearkey monthkey daykey r =
    Dict.get yearkey r
        |> Result.fromMaybe "DateObj missing year"
        |> Result.andThen (String.toInt >> Result.fromMaybe "DateObj year not an integer!")
        |> Result.map
            (\year ->
                Date year (Dict.get monthkey r |> Maybe.andThen String.toInt) (Dict.get daykey r |> Maybe.andThen String.toInt)
            )


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


regionFloatExtents : TimelineRegion -> ( Float, Float )
regionFloatExtents r =
    let
        begin =
            dateToFloat r.start

        end =
            getEnd r |> Maybe.map dateToFloat
    in
    ( begin, Maybe.withDefault begin end )


dateToFloat : Date -> Float
dateToFloat d =
    toFloat d.year
        + toFloat (d.month |> Maybe.withDefault 0)
        / 12.0
        + toFloat (d.day |> Maybe.withDefault 0)
        / (31.0 * 12.0)


view : TimelineRegion -> Html.Html msg
view r =
    let
        startDateString =
            dateString r.start

        maybeEndString =
            getEnd r
                |> Maybe.map dateString

        timespanString =
            case maybeEndString of
                Just endDateString ->
                    startDateString ++ " - " ++ endDateString

                Nothing ->
                    startDateString
    in
    Html.div []
        [ Html.h2 [] [ Html.text r.headline ]
        , Html.h3 [] [ Html.text timespanString ]
        , Html.p [] [ Html.text (r.text |> Maybe.withDefault "") ]
        ]


dateString : Date -> String
dateString date =
    case ( monthString date, dayString date ) of
        ( Just monthName, Just dayName ) ->
            monthName ++ " " ++ dayName ++ ", " ++ String.fromInt date.year

        ( Just monthName, Nothing ) ->
            monthName ++ " " ++ String.fromInt date.year

        ( Nothing, _ ) ->
            String.fromInt date.year


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
