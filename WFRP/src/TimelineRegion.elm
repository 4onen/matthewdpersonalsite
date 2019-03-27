module TimelineRegion exposing
    ( PointData
    , RegionData
    , TimelineRegion(..)
    , getHeadline
    , getYear
    , listFromSheet
    )

import Dict exposing (Dict)


type alias Described a =
    { a | headline : String, text : Maybe String }


type alias PointData =
    Described { year : Int, month : Maybe Int, day : Maybe Int }


type alias RegionData =
    Described { year : Int, month : Maybe Int, day : Maybe Int, endyear : Int, endmonth : Maybe Int, endday : Maybe Int }


type TimelineRegion
    = Point PointData
    | Region RegionData
    | Era RegionData


listFromSheet : List (Dict String String) -> Result (List String) (List TimelineRegion)
listFromSheet =
    List.filterMap fromRow
        >> List.foldl
            (\i o ->
                case ( i, o ) of
                    ( Err err, Err errlist ) ->
                        Err <| err :: errlist

                    ( Err err, _ ) ->
                        Err [ err ]

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


fromRow : Dict String String -> Maybe (Result String TimelineRegion)
fromRow r =
    case Dict.get "type" r of
        Just "title" ->
            Nothing

        Just "era" ->
            r |> regionDataFromRow "era" |> Result.map Era |> Just

        _ ->
            case Dict.member "endyear" r of
                True ->
                    r |> regionDataFromRow "region" |> Result.map Region |> Just

                False ->
                    r |> pointDataFromRow "point" |> Result.map Point |> Just


regionDataFromRow : String -> Dict String String -> Result String RegionData
regionDataFromRow context r =
    let
        startPoint =
            pointDataFromRow context r

        endyear =
            Dict.get "endyear" r
                |> Result.fromMaybe
                    ("Spreadsheet "
                        ++ context
                        ++ " was missing end year!"
                    )
                |> Result.andThen (String.toInt >> Result.fromMaybe ("Spreadsheet " ++ context ++ " end year was not an integer!"))
    in
    Result.map2
        (\{ headline, text, year, month, day } e ->
            { headline = headline
            , text = text
            , year = year
            , month = month
            , day = day
            , endyear = e
            , endmonth = Dict.get "endmonth" r |> Maybe.andThen String.toInt
            , endday = Dict.get "endday" r |> Maybe.andThen String.toInt
            }
        )
        startPoint
        endyear


pointDataFromRow : String -> Dict String String -> Result String PointData
pointDataFromRow context r =
    let
        headline =
            Dict.get "headline" r
                |> Result.fromMaybe
                    ("Spreadsheet "
                        ++ context
                        ++ " was missing headline!"
                    )

        year =
            Dict.get "year" r
                |> Result.fromMaybe
                    ("Spreadsheet "
                        ++ context
                        ++ " was missing start year!"
                    )
                |> Result.andThen (String.toInt >> Result.fromMaybe ("Spreadsheet " ++ context ++ " year was not an integer!"))
    in
    Result.map2
        (\h y ->
            { headline = h
            , text = Dict.get "text" r
            , year = y
            , month = Dict.get "month" r |> Maybe.andThen String.toInt
            , day = Dict.get "day" r |> Maybe.andThen String.toInt
            }
        )
        headline
        year


getHeadline : TimelineRegion -> String
getHeadline r =
    case r of
        Point { headline } ->
            headline

        Region { headline } ->
            headline

        Era { headline } ->
            headline


getYear : TimelineRegion -> Int
getYear r =
    case r of
        Point { year } ->
            year

        Region { year } ->
            year

        Era { year } ->
            year


compare : TimelineRegion -> TimelineRegion -> Basics.Order
compare a b =
    let
        compareMaybes am bm =
            case am of
                Just vala ->
                    case bm of
                        Just valb ->
                            Basics.compare vala valb

                        Nothing ->
                            Basics.GT

                Nothing ->
                    case bm of
                        Just _ ->
                            Basics.LT

                        Nothing ->
                            Basics.EQ

        compyr =
            Basics.compare (getYear a) (getYear b)
    in
    if compyr /= EQ then
        compyr

    else
        let
            getMonth r =
                case r of
                    Point { month } ->
                        month

                    Region { month } ->
                        month

                    Era { month } ->
                        month

            compmonth =
                compareMaybes (getMonth a) (getMonth b)
        in
        if compmonth /= EQ then
            compmonth

        else
            let
                getDay r =
                    case r of
                        Point { day } ->
                            day

                        Region { day } ->
                            day

                        Era { day } ->
                            day

                compday =
                    compareMaybes (getDay a) (getDay b)
            in
            if compday /= EQ then
                compday

            else
                let
                    getEndYear start r =
                        Maybe.withDefault start <|
                            case r of
                                Point _ ->
                                    Nothing

                                Region { endyear } ->
                                    Just endyear

                                Era { endyear } ->
                                    Just endyear

                    compendyear =
                        Basics.compare (getEndYear (getYear a) a) (getEndYear (getYear b) b)
                in
                if compendyear /= EQ then
                    compendyear

                else
                    let
                        getEndMonth start r =
                            Maybe.withDefault 0 <|
                                case r of
                                    Point _ ->
                                        Nothing

                                    Region { endmonth } ->
                                        endmonth

                                    Era { endmonth } ->
                                        endmonth

                        compendmonth =
                            Basics.compare (getEndMonth (getMonth b) a) (getEndMonth (getMonth b) b)
                    in
                    compendmonth -- Too lazy to do compendday.