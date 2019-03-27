module Main exposing (main)

import Browser
import Dict exposing (Dict)
import GSheet
import Html
import Html.Attributes as A
import Http


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
    | Loaded GSheet.Table
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
                Loaded val

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
                parseresult
                    |> List.map
                        (Dict.toList
                            >> viewTable
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
