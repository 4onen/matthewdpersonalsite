module TimelineRegion exposing
    ( PointData
    , RegionData
    , TimelineRegion(..)
    , getHeadline
    , listFromSheet
    , getYear
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
    | Title (Described {})
    | Era RegionData


listFromSheet : List (Dict String String) -> Result (List String) (List TimelineRegion)
listFromSheet =
    List.foldl
        (\i o ->
            case ( fromRow i, o ) of
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


fromRow : Dict String String -> Result String TimelineRegion
fromRow r =
    case Dict.get "type" r of
        Just "title" ->
            r
                |> Dict.get "headline"
                |> Maybe.map (\h -> Title { headline = h, text = Dict.get "text" r })
                |> Result.fromMaybe "Title element missing headline. Add one!"

        Just "era" ->
            r |> regionDataFromRow "era" |> Result.map Era

        _ ->
            case Dict.member "endyear" r of
                True ->
                    r |> regionDataFromRow "region" |> Result.map Region

                False ->
                    r |> pointDataFromRow "point" |> Result.map Point


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

        Title { headline } ->
            headline

        Era { headline } ->
            headline

getYear : TimelineRegion -> Maybe Int
getYear r =
    case r of
        Point {year} ->
            Just year
        Region {year} ->
            Just year
        Era {year} ->
            Just year
        _ ->
            Nothing