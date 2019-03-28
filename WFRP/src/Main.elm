module Main exposing (main)

import Browser
import GSheet
import Html exposing (Html)
import Html.Events as E
import Http
import Timeline exposing (Timeline)


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
    | Loaded Timeline
    | Failure String


type Msg
    = Response (Result Http.Error GSheet.Table)
    | Reload
    | TimelineMsg Timeline.Msg


init : () -> ( Model, Cmd Msg )
init () =
    ( Loading
    , GSheet.getSheet datasheet_key Response
    )


nocmd : a -> ( a, Cmd msg )
nocmd a =
    ( a, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Response result ->
            case result of
                Result.Ok val ->
                    nocmd <|
                        case Timeline.fromSheet val of
                            Result.Ok timeline ->
                                Loaded timeline

                            Result.Err err ->
                                err
                                    |> List.intersperse ","
                                    |> List.foldl (++) ""
                                    |> (\s -> "[" ++ s ++ "]")
                                    |> Failure

                Result.Err err ->
                    nocmd <| Failure <| stringifyHttpError err

        Reload ->
            init ()

        TimelineMsg tlmsg ->
            case model of
                Loaded timeline ->
                    ( Loaded <| Timeline.update tlmsg timeline, Cmd.none )

                _ ->
                    ( model, Cmd.none )


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
            { title = "Loading...", body = [ Html.h2 [] [ Html.text "Timeline loading..." ] ] }

        Loaded timeline ->
            { title = "Timeline"
            , body = reloadButton :: [ Html.map TimelineMsg <| Timeline.view timeline ]
            }

        Failure err ->
            { title = "Oops!"
            , body =
                (::) reloadButton
                    (err
                        |> String.split "\n"
                        |> List.map
                            (Html.text
                                >> List.singleton
                                >> Html.p []
                            )
                    )
            }


reloadButton : Html Msg
reloadButton =
    Html.button [ E.onClick Reload ] [ Html.text "Reload" ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
