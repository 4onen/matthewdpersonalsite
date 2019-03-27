module Main exposing (main)

import Browser
import Dict exposing (Dict)
import GSheet
import Html
import Html.Attributes as A
import Http
import TimelineRegion exposing (TimelineRegion(..))


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


datasheet_key =
    "1lL9-y3zgfcmst_YMpRLVQwzONZD615SD5-FAZtpJqh8"


type Model
    = Loading
    | Loaded (List TimelineRegion)
    | Failure String


type Msg
    = Response (Result Http.Error GSheet.Table)


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading
    , GSheet.getSheet datasheet_key Response
    )


nocmd : a -> ( a, Cmd msg )
nocmd a =
    ( a, Cmd.none )


update : Msg -> Model -> ( Model, Cmd msg )
update (Response result) _ =
    nocmd <|
        case result of
            Result.Ok val ->
                case TimelineRegion.listFromSheet val of
                    Result.Ok ls ->
                        Loaded ls

                    Result.Err err ->
                        err
                            |> List.intersperse ","
                            |> List.foldl (++) ""
                            |> (\s -> "[" ++ s ++ "]")
                            |> Failure

            Result.Err err ->
                Failure <| stringifyHttpError err


stringifyHttpError : Http.Error -> String
stringifyHttpError err =
    case err of
        Http.BadUrl str ->
            "Bad URL! \"" ++ str ++ "\""

        Http.Timeout ->
            "Timeout when trying to connect to Google Spreadsheets..."

        Http.NetworkError ->
            "The network provider changed while I was talking! Refresh?"

        Http.BadStatus i ->
            "HTTP Protocol error code " ++ String.fromInt i ++ " received."

        Http.BadBody errstr ->
            "So there were... a few parsing errors in the spreadsheet. See:\n" ++ errstr


view : Model -> Browser.Document Msg
view model =
    case model of
        Loading ->
            { title = "Loading...", body = [ Html.text "Still loading..." ] }

        Loaded parseresult ->
            { title = "Loaded!"
            , body =
                let
                    yearlist =
                        parseresult |> List.map TimelineRegion.getYear

                    minyear =
                        yearlist |> List.minimum |> Maybe.withDefault 0

                    maxyear =
                        yearlist |> List.maximum |> Maybe.withDefault 0
                in
                parseresult
                    |> List.indexedMap
                        (\i r ->
                            let
                                year =
                                    TimelineRegion.getYear r

                                ey =
                                    case r of
                                        Era { endyear } ->
                                            endyear

                                        Region { endyear } ->
                                            endyear

                                        _ ->
                                            year + 1

                                color =
                                    case r of
                                        Era _ ->
                                            "blue"

                                        Region _ ->
                                            "red"

                                        Point _ ->
                                            "green"
                            in
                            Html.div
                                [ A.style "background-color" color
                                , A.style "position" "absolute"
                                , A.style "height" "1em"
                                , A.style "top" <| String.fromInt i ++ "em"
                                , A.style "width" <| String.fromInt (20 * (ey - year)) ++ "px"
                                , A.style "left" <| String.fromInt (20 * (year - minyear)) ++ "px"
                                ]
                                [r |> TimelineRegion.getHeadline |> Html.text]
                        )
            }

        Failure err ->
            { title = "Oops!"
            , body =
                err
                    |> String.split "\n"
                    |> List.map
                        (Html.text
                            >> List.singleton
                            >> Html.p []
                        )
            }


viewTable : List ( String, String ) -> Html.Html msg
viewTable =
    List.map
        (\( a, b ) ->
            [ a, b ]
                |> List.map (Html.text >> List.singleton >> Html.td [])
                |> Html.tr []
        )
        >> Html.table [ A.style "border" "1px solid black" ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
